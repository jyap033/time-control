import SwiftUI
import UIKit

/// Resolves which app to return the user to after an intervention.
/// The Shortcuts automation passes it via `?app=` (e.g. instagram) or a raw
/// `?url=` scheme. `open(_:)` doesn't need LSApplicationQueriesSchemes.
enum AppLinks {
    static let schemes: [String: String] = [
        "instagram": "instagram://app",
        "tiktok": "tiktok://",
        "youtube": "youtube://",
        "twitter": "twitter://",
        "x": "twitter://",
        "facebook": "fb://",
        "reddit": "reddit://",
        "snapchat": "snapchat://",
        "netflix": "nflx://",
        "twitch": "twitch://",
        "linkedin": "linkedin://",
        "pinterest": "pinterest://",
    ]

    static func resolve(app: String?, rawURL: String?) -> URL? {
        if let rawURL, !rawURL.isEmpty, let u = URL(string: rawURL) { return u }
        guard let key = app?.lowercased(), let scheme = schemes[key] else { return nil }
        return URL(string: scheme)
    }
}

/// Drives the full-screen intervention. Triggered when the app is opened via the
/// `timecontrol://intervene?app=<name>` URL from a Shortcuts "App Opened" automation.
@MainActor
final class InterventionCoordinator: ObservableObject {
    @Published var isPresented = false
    @Published var message = NudgeMessages.randomIntervention

    /// The app to reopen if the user pushes through.
    private var returnURL: URL?
    /// After "Continue", let the user back in without nagging for a short window.
    private var graceUntil: Date?
    /// When we last programmatically reopened the app.
    private var lastReopen: Date?
    /// How many times we've reopened in the current rapid burst.
    private var burstCount = 0

    private let graceDuration: TimeInterval = 3 * 60
    /// Reopens closer together than this are treated as automation echoes.
    private let burstWindow: TimeInterval = 6
    /// Cap on echo reopens so we can never loop forever.
    private let maxBurst = 3
    /// Small deliberate delay before reopening. Lets the automation's re-trigger
    /// settle first, so the reopen "sticks" more reliably (mimics the timing shift
    /// you get from running a second automation alongside this one).
    private let reopenDelay: TimeInterval = 0.4

    /// Entry point from `onOpenURL`.
    func handleIntervene(returnURL: URL?) {
        self.returnURL = returnURL
        let now = Date()
        let graceActive = graceUntil.map { now < $0 } ?? false

        if graceActive {
            let sinceReopen = lastReopen.map { now.timeIntervalSince($0) } ?? .infinity
            if sinceReopen < burstWindow {
                // Rapid re-fire caused by our own reopen. Keep pushing back into
                // the app until iOS settles, but stop after maxBurst so a stubborn
                // OS can't trap us in an infinite flicker.
                if burstCount < maxBurst {
                    reopenApp()
                }
                // else: give up silently — stay in TimeControl, no loop.
            } else {
                // A genuine reopen within the grace window — let them straight in.
                burstCount = 0
                reopenApp()
            }
            return
        }

        // No grace: confront.
        burstCount = 0
        pickMessage()
        isPresented = true
    }

    func continueAnyway() {
        graceUntil = Date().addingTimeInterval(graceDuration)
        burstCount = 0
        isPresented = false
        reopenApp()
    }

    func stop() {
        isPresented = false
        graceUntil = nil
        // No grace, no reopen — the user stays out.
    }

    private func reopenApp() {
        guard let url = returnURL else { return }
        lastReopen = Date()
        burstCount += 1
        // Wait a beat so the automation's re-trigger fires and settles before we
        // reopen, rather than racing it head-on.
        DispatchQueue.main.asyncAfter(deadline: .now() + reopenDelay) {
            UIApplication.shared.open(url)
        }
    }

    private func pickMessage() {
        var next = NudgeMessages.randomIntervention
        if NudgeMessages.interventions.count > 1 {
            while next == message { next = NudgeMessages.randomIntervention }
        }
        message = next
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
                    timer?.invalidate()
                    coordinator.stop()
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
                    if continueUnlockIn == 0 {
                        timer?.invalidate()
                        coordinator.continueAnyway()
                    }
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
}
