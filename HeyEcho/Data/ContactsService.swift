import Foundation
import Contacts

enum ContactsAccessStatus: Equatable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unavailable
}

struct DeviceContact: Identifiable, Hashable {
    var id: String
    var name: String
    var phone: String
    var matchKey: String
}

/// Loads device contacts and matches them against the HeyEcho directory by phone.
enum ContactsService {
    static func accessStatus() -> ContactsAccessStatus {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .notDetermined: return .notDetermined
        case .authorized: return .authorized
        case .denied: return .denied
        case .restricted: return .restricted
        default:
            // Includes iOS 18 `.limited` — treat as usable for matching.
            return .authorized
        }
    }

    static func requestAccess() async -> Bool {
        let store = CNContactStore()
        do {
            return try await store.requestAccess(for: .contacts)
        } catch {
            return false
        }
    }

    static func fetchDeviceContacts() throws -> [DeviceContact] {
        let store = CNContactStore()
        let keys: [CNKeyDescriptor] = [
            CNContactIdentifierKey as CNKeyDescriptor,
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor
        ]
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .givenName

        var results: [DeviceContact] = []
        try store.enumerateContacts(with: request) { contact, _ in
            let name = [contact.givenName, contact.familyName]
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .joined(separator: " ")
            guard !name.isEmpty else { return }

            for labeled in contact.phoneNumbers {
                let raw = labeled.value.stringValue
                let key = PhoneNormalizer.matchKey(raw)
                guard key.count >= 10 else { continue }
                results.append(
                    DeviceContact(
                        id: "\(contact.identifier)-\(key)",
                        name: name,
                        phone: raw,
                        matchKey: key
                    )
                )
            }
        }

        // Prefer unique phones (first name wins)
        var seen = Set<String>()
        return results.filter { seen.insert($0.matchKey).inserted }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Merges device contacts with the HeyEcho directory.
    /// Matched phones become selectable GoTo's; unmatched stay as "invite later".
    static func merge(
        deviceContacts: [DeviceContact],
        directory: [ContactPerson]
    ) -> [ContactPerson] {
        let directoryByPhone = Dictionary(
            directory.map { (PhoneNormalizer.matchKey($0.phone), $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var merged: [ContactPerson] = []
        var claimedDirectoryIds = Set<String>()

        for device in deviceContacts {
            if let match = directoryByPhone[device.matchKey] {
                claimedDirectoryIds.insert(match.id)
                merged.append(
                    ContactPerson(
                        id: match.id,
                        name: device.name.isEmpty ? match.name : device.name,
                        phone: match.phone.isEmpty ? device.phone : match.phone,
                        isOnHeyEcho: true,
                        knownFor: match.knownFor,
                        avatarHue: match.avatarHue
                    )
                )
            } else {
                merged.append(
                    ContactPerson(
                        id: "device-\(device.matchKey)",
                        name: device.name,
                        phone: device.phone,
                        isOnHeyEcho: false,
                        knownFor: [],
                        avatarHue: Double(abs(device.matchKey.hashValue % 1000)) / 1000.0
                    )
                )
            }
        }

        // Keep unmatched directory people (pilot seed) so local/demo still works
        // when the address book has no overlaps.
        for person in directory where !claimedDirectoryIds.contains(person.id) {
            merged.append(person)
        }

        return merged.sorted {
            if $0.isOnHeyEcho != $1.isOnHeyEcho { return $0.isOnHeyEcho && !$1.isOnHeyEcho }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }
}
