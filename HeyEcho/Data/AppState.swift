import Foundation
import Combine

/// App state for Phase 1 — local device storage OR Firebase cloud when configured.
@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var profile: UserProfile
    @Published var selectedGotoIds: Set<String>
    @Published var pendingGotoIds: Set<String>
    @Published var favoriteBusinessIds: Set<String>
    @Published var collections: [FoodCollection]
    @Published var contacts: [ContactPerson]
    @Published var businesses: [Business]
    @Published var tipsByBusinessId: [String: [Tip]] = [:]

    @Published var isBootstrapping = false
    @Published var isSaving = false
    @Published var isLoadingContacts = false
    @Published var authError: String?
    @Published var contactsStatus: ContactsAccessStatus = .notDetermined
    @Published var backendLabel: String = BackendMode.local.rawValue
    @Published var remoteConfig: AppRemoteConfig = .fallback

    let auth = AuthService()
    private let repo = FirestoreRepository()

    private let defaults = UserDefaults.standard
    private let onboardingKey = "heyecho.hasCompletedOnboarding"
    private let profileKey = "heyecho.profile"
    private let favoritesKey = "heyecho.favorites"
    private let gotosKey = "heyecho.gotos"
    private let collectionsKey = "heyecho.collections"

    /// Directory of known HeyEcho users (seed or Firestore) before device-merge.
    private var directoryContacts: [ContactPerson] = StaticData.contacts

    init() {
        let defaults = UserDefaults.standard
        let loaded = Self.loadLocal(defaults: defaults)
        hasCompletedOnboarding = loaded.onboarding
        profile = loaded.profile
        selectedGotoIds = loaded.gotos
        pendingGotoIds = Set(loaded.profile.pendingGotoIds)
        favoriteBusinessIds = loaded.favorites
        collections = loaded.collections
        contacts = StaticData.contacts
        businesses = StaticData.businesses
        backendLabel = FirebaseBootstrap.mode.rawValue
        contactsStatus = ContactsService.accessStatus()
    }

    /// Call after FirebaseBootstrap.configureIfPossible().
    func bootstrap() async {
        backendLabel = FirebaseBootstrap.mode.rawValue
        auth.refreshFromFirebase()
        contactsStatus = ContactsService.accessStatus()

        // Always keep bundled seed visible first so Home/Search never go blank.
        let bundled = PilotSeedLoader.load()
        if businesses.isEmpty || !FirebaseBootstrap.isConfigured {
            applyBundledDirectory(bundled)
        }

        guard FirebaseBootstrap.isConfigured else {
            remoteConfig = bundled.config.foodCities.isEmpty ? .fallback : bundled.config
            await refreshContactsFromDevice(fallbackToDirectory: true)
            return
        }

        isBootstrapping = true
        defer { isBootstrapping = false }

        await loadCloudDirectoryPreferringRemote(fallback: bundled)

        if let uid = auth.userId, !uid.hasPrefix("local_") {
            do {
                if let remote = try await repo.fetchUser(uid: uid) {
                    profile = remote.profile
                    selectedGotoIds = Set(remote.profile.gotoIds)
                    pendingGotoIds = Set(remote.profile.pendingGotoIds)
                    favoriteBusinessIds = Set(remote.profile.favoriteBusinessIds)
                    hasCompletedOnboarding = remote.hasCompletedOnboarding
                    collections = try await repo.fetchCollections(ownerId: uid)
                    if collections.isEmpty {
                        collections = StaticData.sampleCollections
                    }
                    syncCollectionIds()
                } else {
                    profile.id = uid
                    if let phone = auth.phoneNumber {
                        profile.phone = phone
                    }
                }
            } catch {
                // Profile sync can fail on permissions; directory already has fallback.
                if authError == nil {
                    authError = error.localizedDescription
                }
            }
        }
        persistLocalCache()
    }

    /// Tries Firestore directory; on permission/empty errors keeps bundled seed on screen.
    private func loadCloudDirectoryPreferringRemote(fallback: PilotSeedLoader.Payload) async {
        applyBundledDirectory(fallback)

        guard let uid = auth.userId, !uid.hasPrefix("local_") else {
            await refreshContactsFromDevice(fallbackToDirectory: true)
            return
        }

        do {
            try await SeedService.seedPilotDataIfNeeded(using: repo)
        } catch {
            authError = "Could not seed Firebase: \(error.localizedDescription). Showing bundled places."
        }

        do {
            remoteConfig = try await repo.fetchAppConfig()
        } catch {
            remoteConfig = fallback.config.foodCities.isEmpty ? .fallback : fallback.config
        }
        if profile.foodCity.isEmpty {
            profile.foodCity = remoteConfig.defaultFoodCity
        }

        do {
            let remoteContacts = try await repo.fetchContacts()
            let remoteBusinesses = try await repo.fetchBusinesses()
            if remoteBusinesses.isEmpty {
                authError = "Firestore has no businesses yet. Showing bundled Indiranagar places. Publish firestore.rules + enable Anonymous Auth, then relaunch."
            } else {
                directoryContacts = remoteContacts.isEmpty ? fallback.contacts : remoteContacts
                businesses = remoteBusinesses
                contacts = directoryContacts
                authError = nil
            }
        } catch {
            authError = "\(error.localizedDescription) — showing bundled places. Publish firestore.rules in Firebase Console."
            applyBundledDirectory(fallback)
        }

        await refreshContactsFromDevice(fallbackToDirectory: true)
    }

    var personalGotos: [ContactPerson] {
        contacts.filter { selectedGotoIds.contains($0.id) }
    }

    var pendingGotos: [ContactPerson] {
        contacts.filter { pendingGotoIds.contains($0.id) }
    }

    var favoriteBusinesses: [Business] {
        businesses.filter { favoriteBusinessIds.contains($0.id) }
    }

    var isCloudEnabled: Bool { FirebaseBootstrap.isConfigured }

    var selectableGotos: [ContactPerson] {
        contacts.filter { $0.isOnHeyEcho && !$0.isLocalExpert }
    }

    var inviteLaterContacts: [ContactPerson] {
        contacts.filter { !$0.isOnHeyEcho }
    }

    /// Local experts suggested when the personal trust graph is thin (SOW Phase 1).
    var localExpertSuggestions: [ContactPerson] {
        contacts.filter(\.isLocalExpert)
    }

    var needsThinNetworkFallback: Bool {
        (personalGotos.count + pendingGotos.count) < 2
    }

    var activeGotoCount: Int {
        selectedGotoIds.count + pendingGotoIds.count
    }

    /// Cities from remote config ∪ whatever cities exist in the live business directory.
    var availableFoodCities: [String] {
        TrustEngine.availableCities(config: remoteConfig, businesses: businesses)
    }

    func completeOnboarding() {
        profile.gotoIds = Array(selectedGotoIds)
        profile.pendingGotoIds = Array(pendingGotoIds)
        profile.favoriteBusinessIds = Array(favoriteBusinessIds)
        syncCollectionIds()
        hasCompletedOnboarding = true
        Task { await persist() }
    }

    func resetOnboardingForDemo() {
        #if DEBUG
        hasCompletedOnboarding = false
        Task { await persist() }
        #endif
    }

    func toggleGoto(_ id: String) {
        guard contacts.contains(where: { $0.id == id && $0.isOnHeyEcho }) || selectedGotoIds.contains(id) else {
            return
        }
        if selectedGotoIds.contains(id) {
            selectedGotoIds.remove(id)
        } else if activeGotoCount < 5 {
            selectedGotoIds.insert(id)
            pendingGotoIds.remove(id)
        }
        profile.gotoIds = Array(selectedGotoIds)
        profile.pendingGotoIds = Array(pendingGotoIds)
        Task { await persist() }
    }

    func togglePendingGoto(_ id: String) {
        guard contacts.contains(where: { $0.id == id && !$0.isOnHeyEcho }) || pendingGotoIds.contains(id) else {
            return
        }
        if pendingGotoIds.contains(id) {
            pendingGotoIds.remove(id)
        } else if activeGotoCount < 5 {
            pendingGotoIds.insert(id)
            selectedGotoIds.remove(id)
        }
        profile.gotoIds = Array(selectedGotoIds)
        profile.pendingGotoIds = Array(pendingGotoIds)
        Task { await persist() }
    }

    func inviteMessage(for contact: ContactPerson) -> String {
        let sender = profile.name.isEmpty ? "A friend" : profile.name
        return """
        \(sender) added you as a food GoTo on HeyEcho — trusted local food discovery.
        Join HeyEcho and help friends find places they'll actually love.
        """
    }

    func updateKnownFor(_ tags: [String]) {
        profile.knownFor = tags
        Task { await persist() }
    }

    func tips(for businessId: String) -> [Tip] {
        tipsByBusinessId[businessId] ?? []
    }

    func loadTips(for businessId: String) async {
        guard isCloudEnabled else { return }
        do {
            tipsByBusinessId[businessId] = try await repo.fetchTips(businessId: businessId)
        } catch {
            #if DEBUG
            print("[HeyEcho] tips load: \(error.localizedDescription)")
            #endif
        }
    }

    func addTip(businessId: String, text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let tip = Tip(
            id: UUID().uuidString,
            businessId: businessId,
            authorId: profile.id,
            authorName: profile.name.isEmpty ? "You" : profile.name,
            text: trimmed,
            createdAt: Date().timeIntervalSince1970
        )
        var list = tipsByBusinessId[businessId] ?? []
        list.insert(tip, at: 0)
        tipsByBusinessId[businessId] = list
        guard isCloudEnabled, let uid = auth.userId ?? (profile.id != "me" ? profile.id : nil) else { return }
        var toSave = tip
        toSave.authorId = uid
        do {
            try await repo.saveTip(toSave)
            tipsByBusinessId[businessId] = try await repo.fetchTips(businessId: businessId)
        } catch {
            authError = error.localizedDescription
        }
    }

    func toggleFavorite(_ businessId: String) {
        if favoriteBusinessIds.contains(businessId) {
            favoriteBusinessIds.remove(businessId)
        } else {
            favoriteBusinessIds.insert(businessId)
        }
        profile.favoriteBusinessIds = Array(favoriteBusinessIds)
        Task { await persist() }
    }

    func isFavorite(_ businessId: String) -> Bool {
        favoriteBusinessIds.contains(businessId)
    }

    func createCollection(title: String, note: String) {
        let collection = FoodCollection(
            id: UUID().uuidString,
            title: title,
            ownerName: profile.name.isEmpty ? "You" : profile.name,
            businessIds: [],
            note: note
        )
        collections.insert(collection, at: 0)
        syncCollectionIds()
        Task { await persist() }
    }

    func renameCollection(id: String, title: String, note: String) {
        guard let index = collections.firstIndex(where: { $0.id == id }) else { return }
        collections[index].title = title
        collections[index].note = note
        Task { await persist() }
    }

    func deleteCollection(id: String) {
        collections.removeAll { $0.id == id }
        syncCollectionIds()
        Task { await persist() }
    }

    func addBusiness(_ businessId: String, toCollectionId collectionId: String) {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else { return }
        if !collections[index].businessIds.contains(businessId) {
            collections[index].businessIds.append(businessId)
            Task { await persist() }
        }
    }

    func removeBusiness(_ businessId: String, fromCollectionId collectionId: String) {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else { return }
        collections[index].businessIds.removeAll { $0 == businessId }
        Task { await persist() }
    }

    func search(query: String) -> [TrustRankedResult] {
        TrustEngine.rank(
            businesses: businesses,
            contacts: contacts,
            selectedGotoIds: selectedGotoIds,
            foodCity: profile.foodCity,
            query: query,
            config: remoteConfig
        )
    }

    func browse(category: String) -> [TrustRankedResult] {
        search(query: category)
    }

    func contact(id: String) -> ContactPerson? {
        contacts.first { $0.id == id }
    }

    func business(id: String) -> Business? {
        businesses.first { $0.id == id }
    }

    /// Bundled pilot directory when Firestore is empty or unreachable.
    private func applyBundledDirectory(_ seed: PilotSeedLoader.Payload) {
        directoryContacts = seed.contacts
        contacts = seed.contacts
        businesses = seed.businesses
        if !seed.config.foodCities.isEmpty {
            remoteConfig = seed.config
        }
    }

    private func applyBundledDirectoryFallback(reason: String) {
        let seed = PilotSeedLoader.load()
        applyBundledDirectory(seed)
        authError = reason
        #if DEBUG
        print("[HeyEcho] directory fallback: \(reason) — loaded \(seed.businesses.count) bundled businesses")
        #endif
    }

    // MARK: - Contacts

    func requestAndLoadContacts() async {
        isLoadingContacts = true
        defer { isLoadingContacts = false }

        contactsStatus = ContactsService.accessStatus()
        if contactsStatus == .notDetermined {
            let granted = await ContactsService.requestAccess()
            contactsStatus = granted ? .authorized : .denied
        } else {
            contactsStatus = ContactsService.accessStatus()
        }

        await refreshContactsFromDevice(fallbackToDirectory: true)
    }

    private func refreshContactsFromDevice(fallbackToDirectory: Bool) async {
        contactsStatus = ContactsService.accessStatus()
        guard contactsStatus == .authorized else {
            if fallbackToDirectory {
                contacts = directoryContacts
            }
            return
        }

        do {
            let device = try ContactsService.fetchDeviceContacts()
            contacts = ContactsService.merge(deviceContacts: device, directory: directoryContacts)
            // Drop GoTo selections that are no longer selectable
            selectedGotoIds = Set(selectedGotoIds.filter { id in
                contacts.contains { $0.id == id && $0.isOnHeyEcho }
            })
            profile.gotoIds = Array(selectedGotoIds)
        } catch {
            authError = "Could not read contacts: \(error.localizedDescription)"
            if fallbackToDirectory {
                contacts = directoryContacts
            }
        }
    }

    // MARK: - Auth helpers used by onboarding

    func sendOTP() async {
        authError = nil
        do {
            try await auth.sendOTP(to: profile.phone)
        } catch {
            authError = error.localizedDescription
        }
    }

    func verifyOTP(_ code: String) async -> Bool {
        authError = nil
        do {
            let uid = try await auth.verifyOTP(code)
            profile.id = uid
            if let phone = auth.phoneNumber {
                profile.phone = phone
            }

            if isCloudEnabled, auth.userId != nil, !(auth.userId ?? "").hasPrefix("local_") {
                await loadCloudDirectoryPreferringRemote(fallback: PilotSeedLoader.load())
                await persist()
            } else {
                applyBundledDirectory(PilotSeedLoader.load())
                persistLocalCache()
            }
            return true
        } catch {
            authError = error.localizedDescription
            return false
        }
    }

    func signOutCloud() {
        try? auth.signOut()
        hasCompletedOnboarding = false
        selectedGotoIds = []
        favoriteBusinessIds = []
        profile = UserProfile(
            id: "me",
            name: "",
            phone: "",
            foodCity: StaticData.defaultFoodCity,
            knownFor: [],
            gotoIds: [],
            pendingGotoIds: [],
            favoriteBusinessIds: [],
            collectionIds: []
        )
        collections = StaticData.sampleCollections
        directoryContacts = StaticData.contacts
        contacts = StaticData.contacts
        selectedGotoIds = []
        pendingGotoIds = []
        persistLocalCache()
    }

    // MARK: - Persistence

    func persist() async {
        syncCollectionIds()
        persistLocalCache()
        guard isCloudEnabled, let uid = auth.userId ?? (profile.id != "me" ? profile.id : nil) else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            var toSave = profile
            toSave.id = uid
            toSave.gotoIds = Array(selectedGotoIds)
            toSave.pendingGotoIds = Array(pendingGotoIds)
            toSave.favoriteBusinessIds = Array(favoriteBusinessIds)
            toSave.collectionIds = collections.map(\.id)
            profile = toSave
            try await repo.saveUser(toSave, hasCompletedOnboarding: hasCompletedOnboarding)
            for collection in collections {
                try await repo.saveCollection(collection, ownerId: uid)
            }
        } catch {
            authError = error.localizedDescription
        }
    }

    private func syncCollectionIds() {
        profile.collectionIds = collections.map(\.id)
    }

    private func persistLocalCache() {
        defaults.set(hasCompletedOnboarding, forKey: onboardingKey)
        defaults.set(Array(selectedGotoIds), forKey: gotosKey)
        defaults.set(Array(favoriteBusinessIds), forKey: favoritesKey)
        if let profileData = try? JSONEncoder().encode(profile) {
            defaults.set(profileData, forKey: profileKey)
        }
        if let collectionsData = try? JSONEncoder().encode(collections) {
            defaults.set(collectionsData, forKey: collectionsKey)
        }
    }

    private struct LocalBundle {
        var onboarding: Bool
        var profile: UserProfile
        var gotos: Set<String>
        var favorites: Set<String>
        var collections: [FoodCollection]
    }

    private static func loadLocal(defaults: UserDefaults) -> LocalBundle {
        let profile: UserProfile
        if let data = defaults.data(forKey: "heyecho.profile"),
           let saved = try? JSONDecoder().decode(UserProfile.self, from: data) {
            profile = saved
        } else {
            profile = UserProfile(
                id: "me",
                name: "",
                phone: "",
                foodCity: StaticData.defaultFoodCity,
                knownFor: [],
                gotoIds: [],
                pendingGotoIds: [],
                favoriteBusinessIds: [],
                collectionIds: []
            )
        }

        let gotos: Set<String>
        if let ids = defaults.array(forKey: "heyecho.gotos") as? [String] {
            gotos = Set(ids)
        } else {
            gotos = Set(profile.gotoIds)
        }

        let favorites: Set<String>
        if let ids = defaults.array(forKey: "heyecho.favorites") as? [String] {
            favorites = Set(ids)
        } else {
            favorites = Set(profile.favoriteBusinessIds)
        }

        let collections: [FoodCollection]
        if let data = defaults.data(forKey: "heyecho.collections"),
           let saved = try? JSONDecoder().decode([FoodCollection].self, from: data) {
            collections = saved
        } else {
            collections = StaticData.sampleCollections
        }

        return LocalBundle(
            onboarding: defaults.bool(forKey: "heyecho.hasCompletedOnboarding"),
            profile: profile,
            gotos: gotos,
            favorites: favorites,
            collections: collections
        )
    }
}
