import Foundation

/// Central place for identifiers shared across the app and its extensions.
///
/// IMPORTANT: The App Group string below must match the value in every
/// `.entitlements` file. If you change your bundle identifiers, change this too.
enum AppGroup {
    static let identifier = "group.com.example.timecontrol"

    /// The `UserDefaults` suite shared by the app + all extensions.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: identifier) ?? .standard
    }
}

/// Keys used in the shared `UserDefaults` suite.
enum StorageKey {
    static let schedules = "tc.schedules"
    static let sessionHistory = "tc.sessionHistory"
    static let activeSession = "tc.activeSession"
    static let strictMode = "tc.strictMode"
    static let onboardingDone = "tc.onboardingDone"
    static let lifetimeSavedMinutes = "tc.lifetimeSavedMinutes"

    /// Per-activity encoded `FamilyActivitySelection`, keyed by DeviceActivityName.
    static func selection(for activityName: String) -> String {
        "tc.selection.\(activityName)"
    }
}

/// Well-known DeviceActivity activity names. The `ManagedSettingsStore` that
/// shields a given activity is named by the activity's raw value (see the monitor
/// extension), so overlapping schedules / sessions never clobber each other.
enum ActivityID {
    static let focusSession = "tc.focusSession"

    /// Base id for a schedule. Actual monitored activities append `.wd<weekday>`.
    static func scheduleBase(_ id: String) -> String { "tc.sched.\(id)" }

    /// One monitored activity per active weekday (1 = Sun ... 7 = Sat).
    static func schedule(_ id: String, weekday: Int) -> String {
        "tc.sched.\(id).wd\(weekday)"
    }
}
