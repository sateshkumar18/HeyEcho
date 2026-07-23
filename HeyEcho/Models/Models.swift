import Foundation

struct UserProfile: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var phone: String
    var foodCity: String
    var knownFor: [String]
    var gotoIds: [String]
    /// Contacts tagged as GoTo but not yet on HeyEcho (pending invite).
    var pendingGotoIds: [String]
    var favoriteBusinessIds: [String]
    var collectionIds: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, phone, foodCity, knownFor, gotoIds, pendingGotoIds, favoriteBusinessIds, collectionIds
    }

    init(
        id: String,
        name: String,
        phone: String,
        foodCity: String,
        knownFor: [String],
        gotoIds: [String],
        pendingGotoIds: [String] = [],
        favoriteBusinessIds: [String],
        collectionIds: [String]
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.foodCity = foodCity
        self.knownFor = knownFor
        self.gotoIds = gotoIds
        self.pendingGotoIds = pendingGotoIds
        self.favoriteBusinessIds = favoriteBusinessIds
        self.collectionIds = collectionIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        phone = try c.decode(String.self, forKey: .phone)
        foodCity = try c.decode(String.self, forKey: .foodCity)
        knownFor = try c.decodeIfPresent([String].self, forKey: .knownFor) ?? []
        gotoIds = try c.decodeIfPresent([String].self, forKey: .gotoIds) ?? []
        pendingGotoIds = try c.decodeIfPresent([String].self, forKey: .pendingGotoIds) ?? []
        favoriteBusinessIds = try c.decodeIfPresent([String].self, forKey: .favoriteBusinessIds) ?? []
        collectionIds = try c.decodeIfPresent([String].self, forKey: .collectionIds) ?? []
    }
}

struct ContactPerson: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var phone: String
    var isOnHeyEcho: Bool
    var knownFor: [String]
    var avatarHue: Double

    /// Editorial / local-expert style directory entries used for thin-network fallback.
    var isLocalExpert: Bool {
        id.hasPrefix("cgoto")
    }
}

struct Business: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var neighborhood: String
    var city: String
    var categories: [String]
    var shortDescription: String
    var priceLevel: Int
    var perfectFor: [String]
    var recommendedByContactIds: [String]
    var imageSymbol: String
    var address: String
    var hours: String
    var latitude: Double?
    var longitude: Double?

    var priceLabel: String {
        String(repeating: "₹", count: max(min(priceLevel, 4), 1))
    }

    var isHotel: Bool {
        categories.contains { $0.localizedCaseInsensitiveContains("hotel") }
    }
}

struct FoodCollection: Identifiable, Hashable, Codable {
    var id: String
    var title: String
    var ownerName: String
    var businessIds: [String]
    var note: String
}

struct FoodCategory: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var subtitle: String
    var symbol: String
}

/// Free-text tip — no stars or numeric ratings (SOW Phase 1).
struct Tip: Identifiable, Hashable, Codable {
    var id: String
    var businessId: String
    var authorId: String
    var authorName: String
    var text: String
    var createdAt: TimeInterval
}

struct TrustRankedResult: Identifiable, Hashable {
    var id: String { business.id }
    var business: Business
    var trustedRecommenders: [ContactPerson]
    var trustScore: Int
}
