import Foundation
import FirebaseCore
import FirebaseAuth

enum BackendMode: String {
    case local = "Local (device only)"
    case firebase = "Firebase (cloud)"
}

enum FirebaseBootstrap {
    private(set) static var isConfigured = false

    static var mode: BackendMode {
        isConfigured ? .firebase : .local
    }

    /// Call once at launch. Safe if GoogleService-Info.plist is missing (stays local).
    static func configureIfPossible() {
        guard !isConfigured else { return }
        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            print("[HeyEcho] GoogleService-Info.plist not found — running in LOCAL mode.")
            return
        }
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        isConfigured = FirebaseApp.app() != nil

        #if DEBUG
        // Lets Simulator skip APNs/reCAPTCHA hang when using Firebase Console test numbers.
        // Do not enable this for App Store / Release builds.
        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
        print("[HeyEcho] Phone Auth app verification disabled for testing (DEBUG).")
        #endif

        print("[HeyEcho] Backend mode: \(mode.rawValue)")
    }
}
