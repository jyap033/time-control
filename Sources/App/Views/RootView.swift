import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthorizationManager
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            #if FREE_TIER
            MainTabView()
            #else
            if auth.isAuthorized {
                MainTabView()
            } else {
                OnboardingView()
            }
            #endif
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active { auth.refresh() }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Focus", systemImage: "hourglass") }
            #if !FREE_TIER
            SchedulesView()
                .tabItem { Label("Schedules", systemImage: "calendar") }
            #endif
            StatsView()
                .tabItem { Label("Stats", systemImage: "chart.bar.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

/// Shown until the user grants Screen Time access.
struct OnboardingView: View {
    @EnvironmentObject private var auth: AuthorizationManager
    @State private var isRequesting = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "hourglass.circle.fill")
                .font(.system(size: 76))
                .foregroundStyle(.tint)
            Text("TimeControl")
                .font(.largeTitle.bold())
            Text("Block distracting apps, run focus sessions, and take back your time.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                Task { await request() }
            } label: {
                Text(isRequesting ? "Requesting…" : "Grant Screen Time Access")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRequesting)
            .padding(.horizontal, 24)

            Text("TimeControl uses Apple's Screen Time API. Your app usage never leaves your device.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
        }
    }

    private func request() async {
        isRequesting = true
        errorMessage = nil
        let result = await auth.requestAuthorization()
        if case .failure(let error) = result {
            errorMessage = "Couldn't get access: \(error.localizedDescription)"
        }
        isRequesting = false
    }
}
