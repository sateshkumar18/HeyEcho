import Foundation

/// Local offline fallback only. Live data comes from Firestore when cloud is enabled —
/// cities, trust weights, contacts, and businesses are all dynamic (not locked to one pilot).
enum StaticData {
    static var defaultFoodCity: String { AppRemoteConfig.fallback.defaultFoodCity }

    static var foodCities: [String] { AppRemoteConfig.fallback.foodCities }

    /// Single taxonomy shared by Browse tiles and "known for" self-tagging (SOW Phase 1).
    static let foodTaxonomy = [
        "South Indian", "North Indian", "Biryani", "Street Food",
        "Cafe & Coffee", "Chinese", "Seafood", "Desserts",
        "Healthy / Bowls", "Pizza & Pasta", "Chaat", "Filter Coffee",
        "Cloud Kitchens", "Late-Night Food", "Cheap Eats", "Kebabs & Rolls"
    ]

    static let categories: [FoodCategory] = [
        .init(id: "c1", name: "South Indian", subtitle: "Dosa, idli, filter coffee", symbol: "leaf.fill"),
        .init(id: "c2", name: "Biryani", subtitle: "Dum, donne, Hyderabadi", symbol: "flame.fill"),
        .init(id: "c3", name: "Street Food", subtitle: "Chaat, rolls, late-night", symbol: "takeoutbag.and.cup.and.straw.fill"),
        .init(id: "c4", name: "Cafe & Coffee", subtitle: "Work-friendly spots", symbol: "cup.and.saucer.fill"),
        .init(id: "c5", name: "North Indian", subtitle: "Tandoor, thali, gravy", symbol: "fork.knife"),
        .init(id: "c6", name: "Desserts", subtitle: "Ice cream, mithai, cakes", symbol: "birthday.cake.fill"),
        .init(id: "c7", name: "Cloud Kitchens", subtitle: "Delivery-first kitchens", symbol: "bicycle"),
        .init(id: "c8", name: "Kebabs & Rolls", subtitle: "Shawarma, kebabs, wraps", symbol: "flame"),
        .init(id: "c9", name: "Cheap Eats", subtitle: "Budget-friendly locals", symbol: "indianrupeesign.circle"),
        .init(id: "c10", name: "Late-Night Food", subtitle: "Open after 10 PM", symbol: "moon.stars.fill")
    ]

    static let contacts: [ContactPerson] = [
        .init(id: "u1", name: "Ananya Rao", phone: "+91 98000 10001", isOnHeyEcho: true, knownFor: ["South Indian", "Filter Coffee"], avatarHue: 0.12),
        .init(id: "u2", name: "Rahul Mehta", phone: "+91 98000 10002", isOnHeyEcho: true, knownFor: ["Biryani", "North Indian"], avatarHue: 0.55),
        .init(id: "u3", name: "Priya Nair", phone: "+91 98000 10003", isOnHeyEcho: true, knownFor: ["Cafe & Coffee", "Healthy / Bowls"], avatarHue: 0.78),
        .init(id: "u4", name: "Vikram Shah", phone: "+91 98000 10004", isOnHeyEcho: true, knownFor: ["Street Food", "Chaat"], avatarHue: 0.33),
        .init(id: "u5", name: "Sneha Iyer", phone: "+91 98000 10005", isOnHeyEcho: true, knownFor: ["Desserts", "Cafe & Coffee"], avatarHue: 0.90),
        .init(id: "u6", name: "Arjun Das", phone: "+91 98000 10006", isOnHeyEcho: true, knownFor: ["Seafood", "Chinese"], avatarHue: 0.42),
        .init(id: "u7", name: "Meera Kapoor", phone: "+91 98000 10007", isOnHeyEcho: false, knownFor: [], avatarHue: 0.20),
        .init(id: "u8", name: "Karan Malhotra", phone: "+91 98000 10008", isOnHeyEcho: false, knownFor: [], avatarHue: 0.65),
        .init(id: "u9", name: "Divya Krishnan", phone: "+91 98000 10009", isOnHeyEcho: true, knownFor: ["Pizza & Pasta", "Cafe & Coffee"], avatarHue: 0.05),
        .init(id: "u10", name: "Nikhil Bose", phone: "+91 98000 10010", isOnHeyEcho: true, knownFor: ["Biryani", "Street Food"], avatarHue: 0.48)
    ]

    static let businesses: [Business] = [
        .init(
            id: "b1",
            name: "CTR Shri Sagar",
            neighborhood: "Malleshwaram",
            city: "Bengaluru",
            categories: ["South Indian", "Filter Coffee"],
            shortDescription: "Legendary benne masala dosa and strong filter coffee.",
            priceLevel: 1,
            perfectFor: ["Breakfast", "Quick bite"],
            recommendedByContactIds: ["u1", "u5", "u3"],
            imageSymbol: "leaf.fill",
            address: "7th Cross, Malleshwaram",
            hours: "7:30 AM – 12:30 PM, 4:00 – 8:30 PM"
        ),
        .init(
            id: "b2",
            name: "Meghana Foods",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Biryani", "Andhra"],
            shortDescription: "Spicy Andhra-style biryani that Indiranagar swears by.",
            priceLevel: 2,
            perfectFor: ["Dinner", "Group orders"],
            recommendedByContactIds: ["u2", "u10", "u4"],
            imageSymbol: "flame.fill",
            address: "100 Feet Road, Indiranagar",
            hours: "11:30 AM – 11:00 PM"
        ),
        .init(
            id: "b3",
            name: "Mahesh Lunch Home",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Seafood", "Coastal"],
            shortDescription: "Mangalorean seafood classics in a busy local favourite.",
            priceLevel: 3,
            perfectFor: ["Family dinner", "Special occasion"],
            recommendedByContactIds: ["u6", "u2"],
            imageSymbol: "fish.fill",
            address: "100 Feet Road, Indiranagar",
            hours: "12:00 – 3:30 PM, 7:00 – 11:00 PM"
        ),
        .init(
            id: "b4",
            name: "Third Wave Coffee",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Cafe & Coffee"],
            shortDescription: "Reliable specialty coffee and laptop-friendly seating.",
            priceLevel: 2,
            perfectFor: ["Work sessions", "Catch-ups"],
            recommendedByContactIds: ["u3", "u5", "u9", "u1"],
            imageSymbol: "cup.and.saucer.fill",
            address: "12th Main, Indiranagar",
            hours: "8:00 AM – 11:00 PM"
        ),
        .init(
            id: "b5",
            name: "Chaat Street Corner",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Street Food", "Chaat"],
            shortDescription: "Pani puri, sev puri, and late-evening chaat runs.",
            priceLevel: 1,
            perfectFor: ["Evening snack", "After work"],
            recommendedByContactIds: ["u4", "u10"],
            imageSymbol: "takeoutbag.and.cup.and.straw.fill",
            address: "CMH Road, Indiranagar",
            hours: "4:00 – 10:30 PM"
        ),
        .init(
            id: "b6",
            name: "Truffles",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Cafe & Coffee", "Pizza & Pasta"],
            shortDescription: "Burgers, pasta, and long weekend brunches.",
            priceLevel: 2,
            perfectFor: ["Brunch", "Friends"],
            recommendedByContactIds: ["u9", "u3"],
            imageSymbol: "fork.knife",
            address: "80 Feet Road, Indiranagar",
            hours: "11:00 AM – 11:30 PM"
        ),
        .init(
            id: "b7",
            name: "Corner House",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Desserts"],
            shortDescription: "Death by Chocolate and classic Bengaluru ice cream.",
            priceLevel: 2,
            perfectFor: ["Dessert run", "Celebrations"],
            recommendedByContactIds: ["u5", "u1", "u9"],
            imageSymbol: "birthday.cake.fill",
            address: "100 Feet Road, Indiranagar",
            hours: "11:00 AM – 11:30 PM"
        ),
        .init(
            id: "b8",
            name: "Punjabi Nawabi",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["North Indian"],
            shortDescription: "Butter chicken, dal makhani, and generous thalis.",
            priceLevel: 2,
            perfectFor: ["Family lunch", "Comfort food"],
            recommendedByContactIds: ["u2"],
            imageSymbol: "fork.knife",
            address: "12th Main, Indiranagar",
            hours: "12:00 – 3:30 PM, 7:00 – 11:00 PM"
        ),
        .init(
            id: "b9",
            name: "Boat Club Brews",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Cafe & Coffee", "Healthy / Bowls"],
            shortDescription: "Light bowls, cold brew, and quieter afternoon seats.",
            priceLevel: 2,
            perfectFor: ["Solo work", "Healthy lunch"],
            recommendedByContactIds: ["u3"],
            imageSymbol: "leaf.circle.fill",
            address: "Ulsoor Lake Road",
            hours: "9:00 AM – 9:00 PM"
        ),
        .init(
            id: "b10",
            name: "Donne Biryani House",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Biryani"],
            shortDescription: "Donne-style biryani with strong local following.",
            priceLevel: 1,
            perfectFor: ["Quick lunch", "Takeaway"],
            recommendedByContactIds: ["u10", "u4", "u2"],
            imageSymbol: "flame.fill",
            address: "Near ESI Hospital, Indiranagar",
            hours: "11:00 AM – 4:00 PM, 6:30 – 10:30 PM"
        ),
        .init(
            id: "b11",
            name: "Empire Restaurant",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Late-Night Food", "Kebabs & Rolls", "Cheap Eats"],
            shortDescription: "Late-night kebabs, rolls, and biryani for post-work hunger.",
            priceLevel: 1,
            perfectFor: ["Late night", "Groups"],
            recommendedByContactIds: ["u4", "u10", "u2"],
            imageSymbol: "moon.stars.fill",
            address: "100 Feet Road, Indiranagar",
            hours: "11:00 AM – 1:00 AM"
        ),
        .init(
            id: "b12",
            name: "Box8 Cloud Kitchen",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Cloud Kitchens", "North Indian", "Biryani"],
            shortDescription: "Delivery-first bowls and thalis with reliable Indiranagar coverage.",
            priceLevel: 2,
            perfectFor: ["Wfh lunch", "Office orders"],
            recommendedByContactIds: ["u3", "u9"],
            imageSymbol: "bicycle",
            address: "Delivery only · Indiranagar",
            hours: "10:00 AM – 11:00 PM"
        ),
        .init(
            id: "b13",
            name: "Rolls On Wheels",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Kebabs & Rolls", "Street Food", "Cheap Eats"],
            shortDescription: "Kathi rolls and egg rolls that locals recommend without thinking twice.",
            priceLevel: 1,
            perfectFor: ["Quick bite", "After work"],
            recommendedByContactIds: ["u4", "u1"],
            imageSymbol: "flame",
            address: "12th Main, Indiranagar",
            hours: "12:00 – 11:00 PM"
        ),
        .init(
            id: "b14",
            name: "Milano Ice Cream",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Desserts"],
            shortDescription: "Italian-style scoops and a classic Indiranagar dessert stop.",
            priceLevel: 2,
            perfectFor: ["Dessert run", "Date"],
            recommendedByContactIds: ["u5", "u9", "u3"],
            imageSymbol: "birthday.cake.fill",
            address: "100 Feet Road, Indiranagar",
            hours: "11:00 AM – 12:00 AM"
        ),
        .init(
            id: "b15",
            name: "Toit Brewpub",
            neighborhood: "Indiranagar",
            city: "Bengaluru",
            categories: ["Cafe & Coffee", "Pizza & Pasta"],
            shortDescription: "Crowded, trusted Indiranagar hangout for pizza and catch-ups.",
            priceLevel: 3,
            perfectFor: ["Friends", "Celebrations"],
            recommendedByContactIds: ["u9", "u6"],
            imageSymbol: "fork.knife",
            address: "100 Feet Road, Indiranagar",
            hours: "12:00 – 11:30 PM"
        )
    ]

    static let sampleCollections: [FoodCollection] = [
        .init(
            id: "col1",
            title: "Sunday dosa runs",
            ownerName: "You",
            businessIds: ["b1"],
            note: "Where I take out-of-town friends for breakfast."
        ),
        .init(
            id: "col2",
            title: "Late night Indiranagar",
            ownerName: "You",
            businessIds: ["b2", "b5", "b7"],
            note: "Reliable after 9 PM."
        )
    ]
}
