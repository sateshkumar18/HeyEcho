import SwiftUI
import FirebaseAuth

@main
struct HeyEchoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var appState: AppState

    init() {
        FirebaseBootstrap.configureIfPossible()
        _appState = StateObject(wrappedValue: AppState())
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .task {
                    await appState.bootstrap()
                }
                .onOpenURL { url in
                    // reCAPTCHA / Phone Auth redirect callback
                    _ = Auth.auth().canHandle(url)
                }
        }
    }
}
