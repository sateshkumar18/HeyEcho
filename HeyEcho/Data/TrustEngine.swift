import Foundation

/// Remote-tunable Phase 1 settings. Loaded from Firestore `config/app` when cloud is on.
struct AppRemoteConfig: Equatable, Codable {
    var foodCities: [String]
    var gotoWeight: Int
    var cityBoost: Int
    var defaultFoodCity: String

    static let fallback = AppRemoteConfig(
        foodCities: [
            // Bengaluru
            "Indiranagar, Bengaluru",
            "Koramangala, Bengaluru",
            "HSR Layout, Bengaluru",
            "Jayanagar, Bengaluru",
            "Whitefield, Bengaluru",
            "Malleshwaram, Bengaluru",
            // Other metros (design deck) — listings appear as you seed them
            "Bandra West, Mumbai",
            "Andheri West, Mumbai",
            "Connaught Place, Delhi NCR",
            "Gurgaon, Delhi NCR",
            "Jubilee Hills, Hyderabad",
            "Hitech City, Hyderabad",
            "Koregaon Park, Pune",
            "Adyar, Chennai",
            "T Nagar, Chennai"
        ],
        gotoWeight: 3,
        cityBoost: 1,
        defaultFoodCity: "Indiranagar, Bengaluru"
    )
}

/// Phase 1 trust-ranking. Weights come from `AppRemoteConfig` (Firestore), not hard-coded product decisions.
enum TrustEngine {
    static func rank(
        businesses: [Business],
        contacts: [ContactPerson],
        selectedGotoIds: Set<String>,
        foodCity: String,
        query: String,
        config: AppRemoteConfig
    ) -> [TrustRankedResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cityPool = filterByFoodCity(businesses, foodCity: foodCity)

        let pool: [Business]
        if trimmed.isEmpty {
            pool = cityPool
        } else {
            pool = cityPool.filter { business in
                business.name.lowercased().contains(trimmed)
                    || business.categories.joined(separator: " ").lowercased().contains(trimmed)
                    || business.neighborhood.lowercased().contains(trimmed)
                    || business.shortDescription.lowercased().contains(trimmed)
                    || business.city.lowercased().contains(trimmed)
            }
        }

        let gotoWeight = max(config.gotoWeight, 1)
        let cityBoost = max(config.cityBoost, 0)

        return pool.map { business in
            let recommenders = contacts.filter {
                selectedGotoIds.contains($0.id) && business.recommendedByContactIds.contains($0.id)
            }
            let score = recommenders.count * gotoWeight
                + (matchesFoodCity(business, foodCity: foodCity) ? cityBoost : 0)
            return TrustRankedResult(
                business: business,
                trustedRecommenders: recommenders,
                trustScore: score
            )
        }
        .sorted {
            if $0.trustScore != $1.trustScore { return $0.trustScore > $1.trustScore }
            return $0.business.name < $1.business.name
        }
    }

    /// Prefer businesses matching the user's selected city/neighborhood.
    /// Falls back to full catalog if nothing matches yet (empty market → still browsable).
    static func filterByFoodCity(_ businesses: [Business], foodCity: String) -> [Business] {
        let filtered = businesses.filter { matchesFoodCity($0, foodCity: foodCity) }
        return filtered.isEmpty ? businesses : filtered
    }

    static func matchesFoodCity(_ business: Business, foodCity: String) -> Bool {
        let haystack = "\(business.neighborhood), \(business.city)".lowercased()
        let parts = foodCity
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        guard !parts.isEmpty else { return true }
        return parts.contains { haystack.contains($0) }
    }

    /// Cities available to pick = remote config list ∪ cities present in live business data.
    static func availableCities(config: AppRemoteConfig, businesses: [Business]) -> [String] {
        var seen = Set<String>()
        var ordered: [String] = []

        func add(_ raw: String) {
            let city = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !city.isEmpty, seen.insert(city.lowercased()).inserted else { return }
            ordered.append(city)
        }

        for city in config.foodCities { add(city) }
        for business in businesses {
            let label: String
            if business.neighborhood.isEmpty {
                label = business.city
            } else if business.city.isEmpty {
                label = business.neighborhood
            } else {
                label = "\(business.neighborhood), \(business.city)"
            }
            add(label)
        }
        return ordered
    }
}
