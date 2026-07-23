import Foundation
import FirebaseFirestore

enum FirestoreError: LocalizedError {
    case notConfigured
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Firestore is unavailable — Firebase is not configured."
        case .underlying(let message):
            return message
        }
    }
}

/// Cloud reads/writes for Phase 1 collections.
final class FirestoreRepository {
    private var db: Firestore {
        Firestore.firestore()
    }

    private func requireDB() throws -> Firestore {
        guard FirebaseBootstrap.isConfigured else { throw FirestoreError.notConfigured }
        return db
    }

    // MARK: - Users

    struct UserRecord {
        var profile: UserProfile
        var hasCompletedOnboarding: Bool
    }

    func fetchUser(uid: String) async throws -> UserRecord? {
        let db = try requireDB()
        let snap = try await db.collection("users").document(uid).getDocument()
        guard snap.exists, let data = snap.data() else { return nil }
        return UserRecord(
            profile: UserProfile.fromFirestore(data, id: uid),
            hasCompletedOnboarding: data["hasCompletedOnboarding"] as? Bool ?? false
        )
    }

    func saveUser(_ profile: UserProfile, hasCompletedOnboarding: Bool) async throws {
        let db = try requireDB()
        var data = profile.firestoreData
        data["hasCompletedOnboarding"] = hasCompletedOnboarding
        data["updatedAt"] = FieldValue.serverTimestamp()
        try await db.collection("users").document(profile.id).setData(data, merge: true)
    }

    // MARK: - Directory (contacts)

    func fetchContacts() async throws -> [ContactPerson] {
        let db = try requireDB()
        let snap = try await db.collection("contacts").getDocuments()
        return snap.documents.compactMap { ContactPerson.fromFirestore($0.data(), id: $0.documentID) }
            .sorted { $0.name < $1.name }
    }

    func upsertContact(_ contact: ContactPerson) async throws {
        let db = try requireDB()
        try await db.collection("contacts").document(contact.id).setData(contact.firestoreData, merge: true)
    }

    // MARK: - Businesses

    func fetchBusinesses() async throws -> [Business] {
        let db = try requireDB()
        let snap = try await db.collection("businesses").getDocuments()
        return snap.documents.compactMap { Business.fromFirestore($0.data(), id: $0.documentID) }
            .sorted { $0.name < $1.name }
    }

    func upsertBusiness(_ business: Business) async throws {
        let db = try requireDB()
        try await db.collection("businesses").document(business.id).setData(business.firestoreData, merge: true)
    }

    func businessCount() async throws -> Int {
        let db = try requireDB()
        let snap = try await db.collection("businesses").limit(to: 1).getDocuments()
        // Cheap emptiness check; full count not needed for seed gate
        if snap.documents.isEmpty { return 0 }
        let all = try await db.collection("businesses").getDocuments()
        return all.documents.count
    }

    // MARK: - Remote config (dynamic cities + trust weights)

    /// Reads `config/app`. Missing doc → fallback defaults (still fully usable).
    func fetchAppConfig() async throws -> AppRemoteConfig {
        let db = try requireDB()
        let snap = try await db.collection("config").document("app").getDocument()
        guard snap.exists, let data = snap.data() else {
            return .fallback
        }
        return AppRemoteConfig.fromFirestore(data)
    }

    func upsertAppConfig(_ config: AppRemoteConfig) async throws {
        let db = try requireDB()
        let data: [String: Any] = [
            "foodCities": config.foodCities,
            "gotoWeight": config.gotoWeight,
            "cityBoost": config.cityBoost,
            "defaultFoodCity": config.defaultFoodCity
        ]
        try await db.collection("config").document("app").setData(data, merge: true)
    }

    // MARK: - Collections (per user)

    func fetchCollections(ownerId: String) async throws -> [FoodCollection] {
        let db = try requireDB()
        let snap = try await db.collection("collections")
            .whereField("ownerId", isEqualTo: ownerId)
            .getDocuments()
        return snap.documents.compactMap { FoodCollection.fromFirestore($0.data(), id: $0.documentID) }
    }

    func saveCollection(_ collection: FoodCollection, ownerId: String) async throws {
        let db = try requireDB()
        var data = collection.firestoreData
        data["ownerId"] = ownerId
        try await db.collection("collections").document(collection.id).setData(data, merge: true)
    }
}

// MARK: - Firestore mapping

extension UserProfile {
    var firestoreData: [String: Any] {
        [
            "name": name,
            "phone": phone,
            "foodCity": foodCity,
            "knownFor": knownFor,
            "gotoIds": gotoIds,
            "favoriteBusinessIds": favoriteBusinessIds,
            "collectionIds": collectionIds
        ]
    }

    static func fromFirestore(_ data: [String: Any], id: String) -> UserProfile {
        UserProfile(
            id: id,
            name: data["name"] as? String ?? "",
            phone: data["phone"] as? String ?? "",
            foodCity: data["foodCity"] as? String ?? StaticData.defaultFoodCity,
            knownFor: data["knownFor"] as? [String] ?? [],
            gotoIds: data["gotoIds"] as? [String] ?? [],
            favoriteBusinessIds: data["favoriteBusinessIds"] as? [String] ?? [],
            collectionIds: data["collectionIds"] as? [String] ?? []
        )
    }
}

extension ContactPerson {
    var firestoreData: [String: Any] {
        [
            "name": name,
            "phone": phone,
            "isOnHeyEcho": isOnHeyEcho,
            "knownFor": knownFor,
            "avatarHue": avatarHue
        ]
    }

    static func fromFirestore(_ data: [String: Any], id: String) -> ContactPerson? {
        guard let name = data["name"] as? String else { return nil }
        return ContactPerson(
            id: id,
            name: name,
            phone: data["phone"] as? String ?? "",
            isOnHeyEcho: data["isOnHeyEcho"] as? Bool ?? true,
            knownFor: data["knownFor"] as? [String] ?? [],
            avatarHue: data["avatarHue"] as? Double ?? 0.4
        )
    }
}

extension Business {
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "name": name,
            "neighborhood": neighborhood,
            "city": city,
            "categories": categories,
            "shortDescription": shortDescription,
            "priceLevel": priceLevel,
            "perfectFor": perfectFor,
            "recommendedByContactIds": recommendedByContactIds,
            "imageSymbol": imageSymbol,
            "address": address,
            "hours": hours
        ]
        if let latitude { data["latitude"] = latitude }
        if let longitude { data["longitude"] = longitude }
        return data
    }

    static func fromFirestore(_ data: [String: Any], id: String) -> Business? {
        guard let name = data["name"] as? String else { return nil }
        return Business(
            id: id,
            name: name,
            neighborhood: data["neighborhood"] as? String ?? "",
            city: data["city"] as? String ?? "",
            categories: data["categories"] as? [String] ?? [],
            shortDescription: data["shortDescription"] as? String ?? "",
            priceLevel: data["priceLevel"] as? Int ?? 1,
            perfectFor: data["perfectFor"] as? [String] ?? [],
            recommendedByContactIds: data["recommendedByContactIds"] as? [String] ?? [],
            imageSymbol: data["imageSymbol"] as? String ?? "fork.knife",
            address: data["address"] as? String ?? "",
            hours: data["hours"] as? String ?? "",
            latitude: data["latitude"] as? Double,
            longitude: data["longitude"] as? Double
        )
    }
}

extension FoodCollection {
    var firestoreData: [String: Any] {
        [
            "title": title,
            "ownerName": ownerName,
            "businessIds": businessIds,
            "note": note
        ]
    }

    static func fromFirestore(_ data: [String: Any], id: String) -> FoodCollection? {
        guard let title = data["title"] as? String else { return nil }
        return FoodCollection(
            id: id,
            title: title,
            ownerName: data["ownerName"] as? String ?? "",
            businessIds: data["businessIds"] as? [String] ?? [],
            note: data["note"] as? String ?? ""
        )
    }
}

extension AppRemoteConfig {
    static func fromFirestore(_ data: [String: Any]) -> AppRemoteConfig {
        let fallback = AppRemoteConfig.fallback
        let cities = data["foodCities"] as? [String]
        return AppRemoteConfig(
            foodCities: (cities?.isEmpty == false) ? cities! : fallback.foodCities,
            gotoWeight: data["gotoWeight"] as? Int ?? fallback.gotoWeight,
            cityBoost: data["cityBoost"] as? Int ?? fallback.cityBoost,
            defaultFoodCity: data["defaultFoodCity"] as? String ?? fallback.defaultFoodCity
        )
    }
}
