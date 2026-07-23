import Foundation

/// Local / offline helpers only. In Firebase (cloud) mode the app reads directory data
/// from Firestore after `SeedService` uploads `pilot_seed.json`.
enum StaticData {
    private static let seed = PilotSeedLoader.load()

    static var defaultFoodCity: String { seed.config.defaultFoodCity.isEmpty ? AppRemoteConfig.fallback.defaultFoodCity : seed.config.defaultFoodCity }

    static var foodCities: [String] {
        seed.config.foodCities.isEmpty ? AppRemoteConfig.fallback.foodCities : seed.config.foodCities
    }

    /// Single taxonomy shared by Browse tiles and "known for" self-tagging (SOW Phase 1).
    static let foodTaxonomy = [
        "South Indian", "North Indian", "Biryani", "Street Food",
        "Cafe & Coffee", "Chinese", "Seafood", "Desserts",
        "Healthy / Bowls", "Pizza & Pasta", "Chaat", "Filter Coffee",
        "Cloud Kitchens", "Late-Night Food", "Cheap Eats", "Kebabs & Rolls",
        "Hotels", "Fine Dining"
    ]

    static let categories: [FoodCategory] = [
        .init(id: "c1", name: "South Indian", subtitle: "Dosa, idli, filter coffee", symbol: "leaf.fill"),
        .init(id: "c2", name: "Biryani", subtitle: "Dum, donne, Hyderabadi", symbol: "flame.fill"),
        .init(id: "c3", name: "Street Food", subtitle: "Chaat, rolls, late-night", symbol: "takeoutbag.and.cup.and.straw.fill"),
        .init(id: "c4", name: "Cafe & Coffee", subtitle: "Work-friendly spots", symbol: "cup.and.saucer.fill"),
        .init(id: "c5", name: "North Indian", subtitle: "Tandoor, thali, gravy", symbol: "fork.knife"),
        .init(id: "c6", name: "Desserts", subtitle: "Ice cream, mithai, cakes", symbol: "birthday.cake.fill"),
        .init(id: "c7", name: "Hotels", subtitle: "Stays & hotel dining", symbol: "building.2.fill"),
        .init(id: "c8", name: "Cloud Kitchens", subtitle: "Delivery-first kitchens", symbol: "bicycle"),
        .init(id: "c9", name: "Kebabs & Rolls", subtitle: "Shawarma, kebabs, wraps", symbol: "flame"),
        .init(id: "c10", name: "Late-Night Food", subtitle: "Open after 10 PM", symbol: "moon.stars.fill")
    ]

    /// Offline-only directory. Prefer Firestore in cloud mode.
    static var contacts: [ContactPerson] { seed.contacts }
    static var businesses: [Business] { seed.businesses }

    static let sampleCollections: [FoodCollection] = [
        .init(
            id: "col1",
            title: "Sunday dosa runs",
            ownerName: "You",
            businessIds: ["b041", "b020"],
            note: "Where I take out-of-town friends for breakfast."
        ),
        .init(
            id: "col2",
            title: "Late night Indiranagar",
            ownerName: "You",
            businessIds: ["b001", "b010", "b006"],
            note: "Reliable after 9 PM."
        )
    ]
}
