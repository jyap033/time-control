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
                .disabled(selection.itemCount == 0)
            } footer: {
                if selection.itemCount == 0 {
                    Text("Select at least one app or category to block.")
                }
            }
        }
        .sheet(isPresented: $showPicker) {
            AppPickerView(selection: $selection)
        }
    }

    private func durationLabel(_ m: Int) -> String {
        if m < 60 { return "\(m)m" }
        let h = m / 60, r = m % 60
        return r == 0 ? "\(h)h" : "\(h)h \(r)m"
    }
}
