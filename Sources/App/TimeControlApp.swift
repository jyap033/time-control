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
                    // e.g. timecontrol://intervene?app=instagram  (Shortcuts automation)
                    guard url.host == "intervene" || url.path.contains("intervene") else { return }
                    let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
                    let app = items?.first { $0.name == "app" }?.value
                    let raw = items?.first { $0.name == "url" }?.value
                    intervention.handleIntervene(returnURL: AppLinks.resolve(app: app, rawURL: raw))
                }
                .task {
                    await nudges.refreshAuthorization()
                    await nudges.rescheduleNudges()
                }
        }
    }
}
