import Foundation
import Combine

/// App state for Phase 1 — local device storage OR Firebase cloud when configured.
@MainActor
final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var profile: UserProfile
    @Published var selectedGotoIds: Set<String>
    @Published var favoriteBusinessIds: Set<String>
    @Published var collections: [FoodCollection]
    @Published var contacts: [ContactPerson]
    @Published var businesses: [Business]

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

        guard FirebaseBootstrap.isConfigured else {
            remoteConfig = .fallback
            await refreshContactsFromDevice(fallbackToDirectory: true)
            return
        }

        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            contacts = StaticData.contacts
            businesses = StaticData.businesses

            if let uid = auth.userId {
                do {
                    remoteConfig = try await repo.fetchAppConfig()
                } catch {
                    remoteConfig = .fallback
                }
                if profile.foodCity.isEmpty {
                    profile.foodCity = remoteConfig.defaultFoodCity
                }

                do {
                    try await SeedService.seedPilotDataIfNeeded(using: repo)
                } catch {
                    // Production rules deny client directory writes — seed via Console instead.
                    #if DEBUG
                    authError = "Directory seed skipped: \(error.localizedDescription). Import businesses/contacts in Firebase Console if empty."
                    #endif
                }
                directoryContacts = try await repo.fetchContacts()
                businesses = try await repo.fetchBusinesses()
                if directoryContacts.isEmpty {
                    directoryContacts = StaticData.contacts
                }
                if businesses.isEmpty {
                    businesses = StaticData.businesses
                }
                await refreshContactsFromDevice(fallbackToDirectory: true)

                if let remote = try await repo.fetchUser(uid: uid) {
                    profile = remote.profile
                    selectedGotoIds = Set(remote.profile.gotoIds)
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
            }
            persistLocalCache()
        } catch {
            authError = error.localizedDescription
        }
    }

    var personalGotos: [ContactPerson] {
        contacts.filter { selectedGotoIds.contains($0.id) }
    }

    var favoriteBusinesses: [Business] {
        businesses.filter { favoriteBusinessIds.contains($0.id) }
    }

    var isCloudEnabled: Bool { FirebaseBootstrap.isConfigured }

    var selectableGotos: [ContactPerson] {
        contacts.filter(\.isOnHeyEcho)
    }

    var inviteLaterContacts: [ContactPerson] {
        contacts.filter { !$0.isOnHeyEcho }
    }

    /// Cities from remote config ∪ whatever cities exist in the live business directory.
    var availableFoodCities: [String] {
        TrustEngine.availableCities(config: remoteConfig, businesses: businesses)
    }

    func completeOnboarding() {
        profile.gotoIds = Array(selectedGotoIds)
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
        } else if selectedGotoIds.count < 5 {
            selectedGotoIds.insert(id)
        }
        profile.gotoIds = Array(selectedGotoIds)
        Task { await persist() }
    }

    func updateKnownFor(_ tags: [String]) {
        profile.knownFor = tags
        Task { await persist() }
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
                do {
                    try await SeedService.seedPilotDataIfNeeded(using: repo)
                } catch {
                    #if DEBUG
                    print("[HeyEcho] Seed skipped: \(error.localizedDescription)")
                    #endif
                }
                do {
                    remoteConfig = try await repo.fetchAppConfig()
                } catch {
                    remoteConfig = .fallback
                }
                do {
                    directoryContacts = try await repo.fetchContacts()
                    businesses = try await repo.fetchBusinesses()
                } catch {
                    directoryContacts = StaticData.contacts
                    businesses = StaticData.businesses
                }
                if directoryContacts.isEmpty { directoryContacts = StaticData.contacts }
                if businesses.isEmpty { businesses = StaticData.businesses }
                await refreshContactsFromDevice(fallbackToDirectory: true)
                await persist()
            } else {
                // Local / anonymous-disabled path — keep static pilot data
                directoryContacts = StaticData.contacts
                contacts = StaticData.contacts
                businesses = StaticData.businesses
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
            favoriteBusinessIds: [],
            collectionIds: []
        )
        collections = StaticData.sampleCollections
        directoryContacts = StaticData.contacts
        contacts = StaticData.contacts
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
