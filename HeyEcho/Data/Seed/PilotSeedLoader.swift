import Foundation

/// Bundled Phase 1 pilot seed (real Bengaluru locations) uploaded into Firestore.
/// Cloud mode reads from Firebase after seed — not from hard-coded lists.
enum PilotSeedLoader {
    struct Payload: Codable {
        var contacts: [ContactPerson]
        var businesses: [Business]
        var config: AppRemoteConfig
    }

    static func load() -> Payload {
        guard let url = Bundle.main.url(forResource: "pilot_seed", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let payload = try? JSONDecoder().decode(Payload.self, from: data) else {
            return Payload(contacts: [], businesses: [], config: .fallback)
        }
        return payload
    }
}
