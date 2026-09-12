import SwiftUI

/// Configures scheduled "guilt" notifications and explains the Shortcuts-based
/// intervention. Works with no Screen Time entitlement.
struct NudgesView: View {
    @EnvironmentObject private var nudges: NudgeManager
    @State private var draft = NudgeConfig.default

    var body: some View {
        Form {
            Section {
                Toggle("Send me guilt nudges", isOn: $draft.enabled)
            } footer: {
                Text("Ordinary reminders at the times below, with a rotating set of tough-love messages. These fire even when the app is closed.")
            }

            if draft.enabled {
                Section("Times") {
                    ForEach(draft.minutesOfDay.indices, id: \.self) { index in
                        DatePicker(
                            "Nudge \(index + 1)",
                            selection: timeBinding(for: index),
                            displayedComponents: .hourAndMinute
                        )
                    }
                    .onDelete { draft.minutesOfDay.remove(atOffsets: $0) }

                    Button {
                        addTime()
                    } label: {
                        Label("Add a time", systemImage: "plus.circle")
                    }
                    .disabled(draft.minutesOfDay.count >= 8)
                }

                Section {
                    Button {
                        Task { await nudges.sendTestNudge() }
                    } label: {
                        Label("Send a test nudge (in 3s)", systemImage: "bell.badge")
                    }
                }
            }

            Section("Sample messages") {
                ForEach(NudgeMessages.notifications.prefix(4), id: \.self) { msg in
                    Text(msg).font(.subheadline).foregroundStyle(.secondary)
                }
            }

            Section("Block-on-open, without the paid account") {
                Text("iOS can open TimeControl automatically when you launch a distracting app — no developer account needed — using a Shortcuts automation. TimeControl throws up a full-screen intervention; \"Continue anyway\" sends you back into the app with a short grace window.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Make ONE automation per app: Shortcuts → Automation → New → \"App\" → Is Opened → pick ONE app → Run Immediately → New Blank Automation → \"Open URLs\" → enter the address below for that app.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 4) {
                    Text("timecontrol://intervene?app=instagram").font(.footnote.monospaced())
                    Text("timecontrol://intervene?app=tiktok").font(.footnote.monospaced())
                    Text("timecontrol://intervene?app=youtube").font(.footnote.monospaced())
                }
                .foregroundStyle(.secondary)
                Text("Built-in app names: instagram, tiktok, youtube, twitter/x, facebook, reddit, snapchat, netflix, twitch, linkedin, pinterest. For anything else use ?url=<its-scheme> (e.g. ?url=whatsapp://).")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Nudges")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { draft = nudges.config }
        .onDisappear { Task { await nudges.update(config: normalized(draft)) } }
    }

    private func timeBinding(for index: Int) -> Binding<Date> {
        Binding(
            get: {
                let minutes = draft.minutesOfDay[safe: index] ?? 0
                return Calendar.current.date(
                    from: DateComponents(hour: minutes / 60, minute: minutes % 60)
                ) ?? Date()
            },
            set: { newDate in
                let comps = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                draft.minutesOfDay[index] = (comps.hour ?? 0) * 60 + (comps.minute ?? 0)
            }
        )
    }

    private func addTime() {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: Date())
        draft.minutesOfDay.append((comps.hour ?? 9) * 60 + (comps.minute ?? 0))
    }

    private func normalized(_ config: NudgeConfig) -> NudgeConfig {
        var c = config
        c.minutesOfDay = Array(Set(c.minutesOfDay)).sorted()
        return c
    }
}
