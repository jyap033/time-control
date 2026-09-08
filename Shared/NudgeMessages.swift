import Foundation

/// Tough-love messages used for scheduled nudges and the intervention screen.
/// Edit freely — this is the voice of the app.
enum NudgeMessages {

    /// Short, punchy lines for notifications.
    static let notifications: [String] = [
        "You are wasting your life. Put it down.",
        "Is this how you wanted today to go?",
        "The scroll never ends. Your day does.",
        "Future you is begging you to stop.",
        "This isn't rest. It's avoidance.",
        "You said you'd do better than this.",
        "Nothing here is worth your time.",
        "Close the app. Do the thing.",
        "Every minute here is a minute gone forever.",
        "You're stronger than the urge. Prove it.",
        "The feed is designed to eat your life. Don't let it.",
        "What did you actually want to do right now?",
        "Bored? Good. Go make something.",
        "You won't remember this scroll tomorrow.",
        "Discipline now, pride later.",
    ]

    /// Longer lines for the full-screen intervention.
    static let interventions: [String] = [
        "You are wasting your life.",
        "This app is stealing your time.",
        "You opened this on autopilot. Wake up.",
        "Is this really what you want to be doing?",
        "The best version of you isn't in this app.",
        "You'll regret this scroll in ten minutes.",
        "Put the phone down. You know why.",
    ]

    static var randomNotification: String { notifications.randomElement() ?? notifications[0] }
    static var randomIntervention: String { interventions.randomElement() ?? interventions[0] }
}
