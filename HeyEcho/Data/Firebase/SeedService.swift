import Foundation

/// Uploads Phase 1 **real-location** pilot seed into Firestore.
/// Source of truth after seed: Firebase `businesses`, `contacts`, `config/app`.
/// If an older thin demo directory exists, missing docs are merged up to the full seed set.
enum SeedService {
    static func seedPilotDataIfNeeded(using repo: FirestoreRepository) async throws {
        let seed = PilotSeedLoader.load()
        guard !seed.businesses.isEmpty else {
            throw FirestoreError.underlying("Bundled pilot_seed.json missing or empty.")
        }

        let count = try await repo.businessCount()
        // Already at (or above) full pilot size — skip.
        if count >= seed.businesses.count { return }

        for contact in seed.contacts {
            try await repo.upsertContact(contact)
        }
        for business in seed.businesses {
            try await repo.upsertBusiness(business)
        }
        try await repo.upsertAppConfig(seed.config)
    }
}
