import Foundation

struct UserProfile: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var phone: String
    var foodCity: String
    var knownFor: [String]
    var gotoIds: [String]
    var favoriteBusinessIds: [String]
    var collectionIds: [String]
}

struct ContactPerson: Identifiable, Hashable, Codable {
    var id: String
    var name: String
    var phone: String
    var isOnHeyEcho: Bool
    var knownFor: [String]
    var avatarHue: Double
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

struct TrustRankedResult: Identifiable, Hashable {
    var id: String { business.id }
    var business: Business
    var trustedRecommenders: [ContactPerson]
    var trustScore: Int
}
