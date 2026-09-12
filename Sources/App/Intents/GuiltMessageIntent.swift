import AppIntents

/// Exposes a "Random Guilt Message" action to the Shortcuts app.
///
/// Use it in an "App → Is Opened" automation: this action returns a random message
/// from TimeControl's pool, which you feed into a "Show Notification" action. The
/// message list lives in the app (NudgeMessages), so you never paste text into the
/// shortcut, and updating the app updates the messages.
@available(iOS 16.0, *)
struct GuiltMessageIntent: AppIntent {
    static var title: LocalizedStringResource = "Random Guilt Message"
    static var description = IntentDescription(
        "Returns a random tough-love message from TimeControl. Pair it with Show Notification to nag yourself when you open a distracting app."
    )

    /// Runs in the background — never yanks you into TimeControl.
    static var openAppWhenRun: Bool = false

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        .result(value: NudgeMessages.randomAny)
    }
}

/// Makes the action discoverable in Shortcuts and via Siri without any setup.
@available(iOS 16.0, *)
struct TimeControlShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GuiltMessageIntent(),
            phrases: [
                "Guilt me with \(.applicationName)",
                "\(.applicationName) guilt message",
            ],
            shortTitle: "Guilt Message",
            systemImageName: "exclamationmark.bubble.fill"
        )
    }
}
