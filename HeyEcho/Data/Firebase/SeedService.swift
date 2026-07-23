import Foundation

/// First-time upload of bundled `pilot_seed.json` into Firestore.
/// After that, **Firestore Console is the source of truth** — add/edit/delete places there.
/// The app will not overwrite a non-empty `businesses` collection from the bundle.
enum SeedService {
    static func seedPilotDataIfNeeded(using repo: FirestoreRepository) async throws {
        let seed = PilotSeedLoader.load()
        guard !seed.businesses.isEmpty else {
            throw FirestoreError.underlying("Bundled pilot_seed.json missing or empty.")
        }

        let count = try await repo.businessCount()
        // Any existing Console / prior seed data wins — do not re-merge the bundle.
        if count > 0 { return }

        for contact in seed.contacts {
            try await repo.upsertContact(contact)
        }
        for business in seed.businesses {
            try await repo.upsertBusiness(business)
        }
        try await repo.upsertAppConfig(seed.config)
    }
}
