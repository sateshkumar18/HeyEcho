import Foundation

/// Normalizes phone numbers for contact matching (India-first, Phase 1).
enum PhoneNormalizer {
    /// Digits only, stripped of leading country code when present.
    static func digits(_ raw: String) -> String {
        let all = raw.filter(\.isNumber)
        if all.count == 12, all.hasPrefix("91") {
            return String(all.suffix(10))
        }
        if all.count == 11, all.hasPrefix("0") {
            return String(all.suffix(10))
        }
        if all.count > 10 {
            return String(all.suffix(10))
        }
        return all
    }

    /// Stable match key used across device contacts and directory entries.
    static func matchKey(_ raw: String) -> String {
        digits(raw)
    }

    static func isValidIndianMobile(_ raw: String) -> Bool {
        let d = digits(raw)
        return d.count == 10 && (d.first == "6" || d.first == "7" || d.first == "8" || d.first == "9")
    }
}
