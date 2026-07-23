import Foundation
import FirebaseAuth

enum AuthError: LocalizedError {
    case firebaseNotConfigured
    case invalidPhone
    case missingVerification
    case underlying(String)

    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase is not connected."
        case .invalidPhone:
            return "Enter a valid 10-digit Indian mobile number."
        case .missingVerification:
            return "Tap Send code first."
        case .underlying(let message):
            return message
        }
    }
}

/// Phase 1 auth: Phone Auth on Simulator hangs (reCAPTCHA/APNs).
/// We use a fixed test OTP + Anonymous Firebase session so onboarding always continues.
@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var userId: String?
    @Published private(set) var phoneNumber: String?
    @Published private(set) var otpReady = false

    private static let testOTP = "123456"

    var isSignedIn: Bool { userId != nil }

    init() {
        refreshFromFirebase()
    }

    func refreshFromFirebase() {
        guard FirebaseBootstrap.isConfigured else {
            userId = nil
            phoneNumber = nil
            return
        }
        let user = Auth.auth().currentUser
        userId = user?.uid
        phoneNumber = user?.phoneNumber
    }

    static func e164IndianPhone(from raw: String) -> String? {
        let digits = raw.filter(\.isNumber)
        if digits.count == 10 {
            return "+91\(digits)"
        }
        if digits.count == 12, digits.hasPrefix("91") {
            return "+\(digits)"
        }
        if raw.trimmingCharacters(in: .whitespaces).hasPrefix("+"), digits.count >= 10 {
            return "+\(digits)"
        }
        return nil
    }

    /// Instant — does not wait on Firebase Phone Auth (that call hangs on Simulator).
    func sendOTP(to rawPhone: String) async throws {
        guard let e164 = Self.e164IndianPhone(from: rawPhone) else {
            throw AuthError.invalidPhone
        }
        phoneNumber = e164
        otpReady = true
        print("[HeyEcho] OTP ready for \(e164). Use code \(Self.testOTP).")
    }

    /// Accepts fixed test code `123456`, then signs into Firebase (Anonymous) for Firestore.
    func verifyOTP(_ code: String) async throws -> String {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard otpReady || phoneNumber != nil else { throw AuthError.missingVerification }
        guard trimmed == Self.testOTP else {
            throw AuthError.underlying("Invalid verification code. Please try again.")
        }

        if FirebaseBootstrap.isConfigured {
            do {
                let result = try await signInAnonymously()
                userId = result.user.uid
                print("[HeyEcho] Signed in anonymously as \(result.user.uid)")
                return result.user.uid
            } catch {
                // Anonymous provider may be disabled — still allow onboarding locally.
                let localId = "local_" + UUID().uuidString
                userId = localId
                print("[HeyEcho] Anonymous Auth failed (\(error.localizedDescription)). Continuing with \(localId). Enable Anonymous sign-in in Firebase Console.")
                return localId
            }
        } else {
            let localId = UUID().uuidString
            userId = localId
            return localId
        }
    }

    private func signInAnonymously() async throws -> AuthDataResult {
        try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signInAnonymously { result, error in
                if let error {
                    continuation.resume(throwing: AuthError.underlying(error.localizedDescription))
                    return
                }
                guard let result else {
                    continuation.resume(throwing: AuthError.underlying("Anonymous sign-in failed."))
                    return
                }
                continuation.resume(returning: result)
            }
        }
    }

    func signOut() throws {
        if FirebaseBootstrap.isConfigured {
            try? Auth.auth().signOut()
        }
        userId = nil
        phoneNumber = nil
        otpReady = false
    }
}
