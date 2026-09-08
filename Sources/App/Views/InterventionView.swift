import SwiftUI

/// Drives the full-screen intervention. Triggered when the app is opened via the
/// `timecontrol://intervene` URL from a Shortcuts "App Opened" automation.
@MainActor
final class InterventionCoordinator: ObservableObject {
    @Published var isPresented = false
    @Published var message = NudgeMessages.randomIntervention

    func trigger() {
        message = NudgeMessages.randomIntervention
        isPresented = true
    }
}

struct InterventionView: View {
    @EnvironmentObject private var coordinator: InterventionCoordinator
    @State private var continueUnlockIn = 10
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.55, green: 0.05, blue: 0.09),
                         Color(red: 0.18, green: 0.02, blue: 0.05)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.white)

                Text(coordinator.message)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                Text("Take a breath. You don't have to do this.")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Text("You're right — I'll stop")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.white)
                        .foregroundStyle(Color(red: 0.55, green: 0.05, blue: 0.09))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    if continueUnlockIn == 0 { dismiss() }
                } label: {
                    Text(continueUnlockIn > 0 ? "Continue anyway (\(continueUnlockIn))" : "Continue anyway")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(.white.opacity(continueUnlockIn > 0 ? 0.4 : 0.9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.4), lineWidth: 1)
                        )
                }
                .disabled(continueUnlockIn > 0)

                Spacer().frame(height: 12)
            }
            .padding(.horizontal, 24)
        }
        .onAppear { startCountdown() }
        .onDisappear { timer?.invalidate() }
    }

    private func startCountdown() {
        continueUnlockIn = 10
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in
                if continueUnlockIn > 0 { continueUnlockIn -= 1 }
            }
        }
    }

    private func dismiss() {
        timer?.invalidate()
        coordinator.isPresented = false
    }
}
