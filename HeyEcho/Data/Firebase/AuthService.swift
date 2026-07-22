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
            return "Firebase is not connected. Add GoogleService-Info.plist (see FIREBASE_SETUP.md)."
        case .invalidPhone:
            return "Enter a valid 10-digit Indian mobile number."
        case .missingVerification:
            return "Request an OTP first."
        case .underlying(let message):
            return message
        }
    }
}

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var userId: String?
    @Published private(set) var phoneNumber: String?

    private var verificationID: String?

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

    /// Formats raw input to E.164 (+91…).
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

    func sendOTP(to rawPhone: String) async throws {
        guard FirebaseBootstrap.isConfigured else { throw AuthError.firebaseNotConfigured }
        guard let e164 = Self.e164IndianPhone(from: rawPhone) else { throw AuthError.invalidPhone }

        let id: String = try await withCheckedThrowingContinuation { continuation in
            PhoneAuthProvider.provider().verifyPhoneNumber(e164, uiDelegate: nil) { verificationID, error in
                if let error {
                    continuation.resume(throwing: AuthError.underlying(error.localizedDescription))
                    return
                }
                guard let verificationID else {
                    continuation.resume(throwing: AuthError.underlying("No verification ID returned."))
                    return
                }
                continuation.resume(returning: verificationID)
            }
        }
        verificationID = id
        phoneNumber = e164
    }

    func verifyOTP(_ code: String) async throws -> String {
        guard FirebaseBootstrap.isConfigured else { throw AuthError.firebaseNotConfigured }
        guard let verificationID else { throw AuthError.missingVerification }

        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: code.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        let result: AuthDataResult = try await withCheckedThrowingContinuation { continuation in
            Auth.auth().signIn(with: credential) { result, error in
                if let error {
                    continuation.resume(throwing: AuthError.underlying(error.localizedDescription))
                    return
                }
                guard let result else {
                    continuation.resume(throwing: AuthError.underlying("Sign-in failed."))
                    return
                }
                continuation.resume(returning: result)
            }
        }

        userId = result.user.uid
        phoneNumber = result.user.phoneNumber
        return result.user.uid
    }

    func signOut() throws {
        guard FirebaseBootstrap.isConfigured else { return }
        try Auth.auth().signOut()
        userId = nil
        phoneNumber = nil
        verificationID = nil
    }
}
