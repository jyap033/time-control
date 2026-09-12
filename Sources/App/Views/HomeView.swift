import SwiftUI
import FamilyControls

struct HomeView: View {
    @EnvironmentObject private var appState: AppState

    @State private var selection = FamilyActivitySelection()
    @State private var showPicker = false
    @State private var minutes: Int = 25
    @State private var strict: Bool = false

    private let presets = [15, 25, 45, 60, 90, 120]

    var body: some View {
        NavigationStack {
            Group {
                if appState.activeSession != nil {
                    FocusSessionView()
                } else {
                    setupForm
                }
            }
            .navigationTitle("Focus")
        }
        .onAppear { strict = appState.strictModeDefault }
    }

    private var setupForm: some View {
        Form {
            #if FREE_TIER
            Section {
                Label("Timer mode", systemImage: "hourglass")
                    .font(.headline)
            } footer: {
                Text("This build runs a focus timer and fires guilt notifications. To actually block apps, set up the Shortcuts automation in Settings → Nudges, or enroll in the paid Apple Developer Program for real in-app blocking.")
            }
            #else
            Section("Apps to block") {
                Button {
                    showPicker = true
                } label: {
                    HStack {
                        Label("Choose apps", systemImage: "apps.iphone")
                        Spacer()
                        Text(selection.summaryText)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            #endif

            Section("Duration") {
                Picker("Length", selection: $minutes) {
                    ForEach(presets, id: \.self) { m in
                        Text(durationLabel(m)).tag(m)
                    }
                }
                .pickerStyle(.segmented)

                Stepper(value: $minutes, in: 5...480, step: 5) {
                    Text("\(durationLabel(minutes))")
                }
            }

            Section {
                Toggle(isOn: $strict) {
                    Label("Strict mode", systemImage: "lock.shield")
                }
            } footer: {
                Text("In strict mode you can't end the session early. No cheating.")
            }

            Section {
                Button {
                    appState.startFocusSession(selection: selection, minutes: minutes, strict: strict)
                } label: {
                    Text("Start Focus Session")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                #if !FREE_TIER
                .disabled(selection.itemCount == 0)
                #endif
            } footer: {
                #if !FREE_TIER
                if selection.itemCount == 0 {
                    Text("Select at least one app or category to block.")
                }
                #endif
            }
        }
        #if !FREE_TIER
        .sheet(isPresented: $showPicker) {
            AppPickerView(selection: $selection)
        }
        #endif
    }

    private func durationLabel(_ m: Int) -> String {
        if m < 60 { return "\(m)m" }
        let h = m / 60, r = m % 60
        return r == 0 ? "\(h)h" : "\(h)h \(r)m"
    }
}
