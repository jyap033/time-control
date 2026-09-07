import SwiftUI

/// The active-session screen: a live countdown ring and an end control.
struct FocusSessionView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showEndConfirm = false

    var body: some View {
        if let session = appState.activeSession {
            VStack(spacing: 32) {
                Spacer()

                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    let remaining = session.remaining
                    let progress = 1 - (remaining / max(1, session.endDate.timeIntervalSince(session.startDate)))

                    ZStack {
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 16)
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 1), value: progress)
                        VStack(spacing: 6) {
                            Text(timeString(remaining))
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .monospacedDigit()
                            Text("remaining")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(width: 260, height: 260)
                }

                if session.isStrict {
                    Label("Strict mode — locked in", systemImage: "lock.shield.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }

                Spacer()

                if appState.canEndEarly {
                    Button(role: .destructive) {
                        showEndConfirm = true
                    } label: {
                        Text("End session")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .padding(.horizontal, 24)
                } else {
                    Text("You committed to this. Stay with it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 8)
                }
            }
            .padding(.bottom, 24)
            .confirmationDialog("End this focus session early?",
                                isPresented: $showEndConfirm,
                                titleVisibility: .visible) {
                Button("End session", role: .destructive) {
                    appState.endFocusSession(completed: false)
                }
                Button("Keep focusing", role: .cancel) {}
            }
        }
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded())
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}
