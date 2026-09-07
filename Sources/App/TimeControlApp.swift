import SwiftUI

@main
struct TimeControlApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var auth = AuthorizationManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(auth)
                .tint(.accentColor)
        }
    }
}
