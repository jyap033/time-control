import SwiftUI

@main
struct TimeControlApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var auth = AuthorizationManager()
    @StateObject private var nudges = NudgeManager()
    @StateObject private var intervention = InterventionCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(auth)
                .environmentObject(nudges)
                .environmentObject(intervention)
                .tint(.accentColor)
                .fullScreenCover(isPresented: $intervention.isPresented) {
                    InterventionView()
                        .environmentObject(intervention)
                }
                .onOpenURL { url in
                    // e.g. timecontrol://intervene  (from a Shortcuts automation)
                    if url.host == "intervene" || url.path.contains("intervene") {
                        intervention.trigger()
                    }
                }
                .task {
                    await nudges.refreshAuthorization()
                    await nudges.rescheduleNudges()
                }
        }
    }
}
