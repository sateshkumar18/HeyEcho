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
    @Published var authError: String?
    @Published var backendLabel: String = BackendMode.local.rawValue

    let auth = AuthService()
    private let repo = FirestoreRepository()

    private let defaults = UserDefaults.standard
    private let onboardingKey = "heyecho.hasCompletedOnboarding"
    private let profileKey = "heyecho.profile"
    private let favoritesKey = "heyecho.favorites"
    private let gotosKey = "heyecho.gotos"
    private let collectionsKey = "heyecho.collections"

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
    }

    /// Call after FirebaseBootstrap.configureIfPossible().
    func bootstrap() async {
        backendLabel = FirebaseBootstrap.mode.rawValue
        auth.refreshFromFirebase()

        guard FirebaseBootstrap.isConfigured else { return }

        isBootstrapping = true
        defer { isBootstrapping = false }

        do {
            contacts = StaticData.contacts
            businesses = StaticData.businesses

            if let uid = auth.userId {
                try await SeedService.seedPilotDataIfNeeded(using: repo)
                contacts = try await repo.fetchContacts()
                businesses = try await repo.fetchBusinesses()

                if let remote = try await repo.fetchUser(uid: uid) {
                    profile = remote.profile
                    selectedGotoIds = Set(remote.profile.gotoIds)
                    favoriteBusinessIds = Set(remote.profile.favoriteBusinessIds)
                    hasCompletedOnboarding = remote.hasCompletedOnboarding
                    collections = try await repo.fetchCollections(ownerId: uid)
                    if collections.isEmpty {
                        collections = StaticData.sampleCollections
                    }
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

    func completeOnboarding() {
        profile.gotoIds = Array(selectedGotoIds)
        profile.favoriteBusinessIds = Array(favoriteBusinessIds)
        hasCompletedOnboarding = true
        Task { await persist() }
    }

    func resetOnboardingForDemo() {
        hasCompletedOnboarding = false
        Task { await persist() }
    }

    func toggleGoto(_ id: String) {
        if selectedGotoIds.contains(id) {
            selectedGotoIds.remove(id)
        } else if selectedGotoIds.count < 5 {
            selectedGotoIds.insert(id)
        }
        profile.gotoIds = Array(selectedGotoIds)
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
        Task { await persist() }
    }

    func addBusiness(_ businessId: String, toCollectionId collectionId: String) {
        guard let index = collections.firstIndex(where: { $0.id == collectionId }) else { return }
        if !collections[index].businessIds.contains(businessId) {
            collections[index].businessIds.append(businessId)
            Task { await persist() }
        }
    }

    func search(query: String) -> [TrustRankedResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pool: [Business]
        if trimmed.isEmpty {
            pool = businesses
        } else {
            pool = businesses.filter {
                $0.name.lowercased().contains(trimmed)
                    || $0.categories.joined(separator: " ").lowercased().contains(trimmed)
                    || $0.neighborhood.lowercased().contains(trimmed)
                    || $0.shortDescription.lowercased().contains(trimmed)
            }
        }

        return pool.map { business in
            let recommenders = contacts.filter {
                selectedGotoIds.contains($0.id) && business.recommendedByContactIds.contains($0.id)
            }
            return TrustRankedResult(
                business: business,
                trustedRecommenders: recommenders,
                trustScore: recommenders.count
            )
        }
        .sorted {
            if $0.trustScore != $1.trustScore { return $0.trustScore > $1.trustScore }
            return $0.business.name < $1.business.name
        }
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

    // MARK: - Auth helpers used by onboarding

    func sendOTP() async {
        authError = nil
        do {
            if isCloudEnabled {
                try await auth.sendOTP(to: profile.phone)
            }
            // Local mode: OTP UI accepts demo code without network
        } catch {
            authError = error.localizedDescription
        }
    }

    func verifyOTP(_ code: String) async -> Bool {
        authError = nil
        if isCloudEnabled {
            do {
                let uid = try await auth.verifyOTP(code)
                profile.id = uid
                if let phone = auth.phoneNumber {
                    profile.phone = phone
                }
                try await SeedService.seedPilotDataIfNeeded(using: repo)
                contacts = try await repo.fetchContacts()
                businesses = try await repo.fetchBusinesses()
                await persist()
                return true
            } catch {
                authError = error.localizedDescription
                return false
            }
        } else {
            // Local production-shaped demo: fixed test OTP
            guard code == "123456" else {
                authError = "Invalid OTP. In local mode use 123456."
                return false
            }
            if profile.id == "me" || profile.id.isEmpty {
                profile.id = UUID().uuidString
            }
            return true
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
            foodCity: StaticData.pilotCity,
            knownFor: [],
            gotoIds: [],
            favoriteBusinessIds: [],
            collectionIds: []
        )
        collections = StaticData.sampleCollections
        persistLocalCache()
    }

    // MARK: - Persistence

    func persist() async {
        persistLocalCache()
        guard isCloudEnabled, let uid = auth.userId ?? (profile.id != "me" ? profile.id : nil) else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            var toSave = profile
            toSave.id = uid
            toSave.gotoIds = Array(selectedGotoIds)
            toSave.favoriteBusinessIds = Array(favoriteBusinessIds)
            profile = toSave
            try await repo.saveUser(toSave, hasCompletedOnboarding: hasCompletedOnboarding)
            for collection in collections {
                try await repo.saveCollection(collection, ownerId: uid)
            }
        } catch {
            authError = error.localizedDescription
        }
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
                foodCity: StaticData.pilotCity,
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
