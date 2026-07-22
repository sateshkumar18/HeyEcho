import Foundation

/// Uploads Phase 1 pilot seed into Firestore when collections are empty.
///
/// Production: seed via Firebase Console / Admin SDK, then publish locked rules
/// from `firestore.rules` (client writes to contacts/businesses are denied).
/// Client seeding is Debug-only so Release builds never mutate the directory.
enum SeedService {
    static func seedPilotDataIfNeeded(using repo: FirestoreRepository) async throws {
        #if DEBUG
        let count = try await repo.businessCount()
        guard count == 0 else { return }

        for contact in StaticData.contacts {
            try await repo.upsertContact(contact)
        }
        for business in StaticData.businesses {
            try await repo.upsertBusiness(business)
        }
        #else
        _ = repo
        #endif
    }
}
