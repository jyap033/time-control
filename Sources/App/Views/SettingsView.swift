import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var auth: AuthorizationManager
    @EnvironmentObject private var nudges: NudgeManager

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: Binding(
                        get: { appState.strictModeDefault },
                        set: { appState.setStrictModeDefault($0) }
                    )) {
                        Label("Strict mode by default", systemImage: "lock.shield")
                    }
                } footer: {
                    Text("New focus sessions start with strict mode on, so they can't be ended early.")
                }

                Section("Nudges & interventions") {
                    NavigationLink {
                        NudgesView()
                    } label: {
                        HStack {
                            Label("Guilt nudges", systemImage: "bell.badge")
                            Spacer()
                            Text(nudges.config.enabled ? "On" : "Off")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Screen Time") {
                    HStack {
                        Label("Access", systemImage: "checkmark.shield")
                        Spacer()
                        Text(auth.isAuthorized ? "Granted" : "Not granted")
                            .foregroundStyle(auth.isAuthorized ? .green : .red)
                    }
                }

                Section("About") {
                    LabeledContent("App", value: "TimeControl")
                    LabeledContent("Version", value: appVersion)
                    Link(destination: URL(string: "https://support.apple.com/en-us/HT210387")!) {
                        Label("About Screen Time", systemImage: "info.circle")
                    }
                }

                Section {
                    Text("TimeControl runs entirely on your device using Apple's Screen Time API. Your app-usage data is never collected or sent anywhere.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }
}
