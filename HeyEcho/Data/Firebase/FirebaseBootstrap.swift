import Foundation
import FirebaseCore

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
        print("[HeyEcho] Backend mode: \(mode.rawValue)")
    }
}
