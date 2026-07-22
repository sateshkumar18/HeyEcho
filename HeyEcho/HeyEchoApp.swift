import SwiftUI

@main
struct HeyEchoApp: App {
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
        }
    }
}
