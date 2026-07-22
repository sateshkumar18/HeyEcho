import Foundation

/// Uploads Phase 1 pilot seed into Firestore when collections are empty.
enum SeedService {
    static func seedPilotDataIfNeeded(using repo: FirestoreRepository) async throws {
        let count = try await repo.businessCount()
        guard count == 0 else { return }

        for contact in StaticData.contacts {
            try await repo.upsertContact(contact)
        }
        for business in StaticData.businesses {
            try await repo.upsertBusiness(business)
        }
    }
}
