import Foundation
import FamilyControls

/// Thin persistence layer over the shared App Group `UserDefaults`.
/// Used by the app AND the extensions, so keep it dependency-free.
enum SharedStore {

    private static var defaults: UserDefaults { AppGroup.defaults }
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()

    // MARK: Schedules

    static func loadSchedules() -> [BlockSchedule] {
        guard let data = defaults.data(forKey: StorageKey.schedules),
              let decoded = try? decoder.decode([BlockSchedule].self, from: data)
        else { return [] }
        return decoded
    }

    static func saveSchedules(_ schedules: [BlockSchedule]) {
        defaults.set(try? encoder.encode(schedules), forKey: StorageKey.schedules)
    }

    // MARK: Per-activity selection (read by the monitor extension)

    static func saveSelection(_ selection: FamilyActivitySelection, for activityID: String) {
        defaults.set(try? encoder.encode(selection), forKey: StorageKey.selection(for: activityID))
    }

    static func selection(for activityID: String) -> FamilyActivitySelection? {
        guard let data = defaults.data(forKey: StorageKey.selection(for: activityID)),
              let decoded = try? decoder.decode(FamilyActivitySelection.self, from: data)
        else { return nil }
        return decoded
    }

    // MARK: Active session

    static func loadActiveSession() -> ActiveSession? {
        guard let data = defaults.data(forKey: StorageKey.activeSession),
              let decoded = try? decoder.decode(ActiveSession.self, from: data)
        else { return nil }
        return decoded
    }

    static func saveActiveSession(_ session: ActiveSession?) {
        if let session {
            defaults.set(try? encoder.encode(session), forKey: StorageKey.activeSession)
        } else {
            defaults.removeObject(forKey: StorageKey.activeSession)
        }
    }

    // MARK: Session history

    static func loadHistory() -> [SessionRecord] {
        guard let data = defaults.data(forKey: StorageKey.sessionHistory),
              let decoded = try? decoder.decode([SessionRecord].self, from: data)
        else { return [] }
        return decoded
    }

    static func appendHistory(_ record: SessionRecord) {
        var history = loadHistory()
        history.append(record)
        defaults.set(try? encoder.encode(history), forKey: StorageKey.sessionHistory)
    }

    // MARK: Settings

    static var strictModeDefault: Bool {
        get { defaults.bool(forKey: StorageKey.strictMode) }
        set { defaults.set(newValue, forKey: StorageKey.strictMode) }
    }

    static var onboardingDone: Bool {
        get { defaults.bool(forKey: StorageKey.onboardingDone) }
        set { defaults.set(newValue, forKey: StorageKey.onboardingDone) }
    }

    static func loadNudgeConfig() -> NudgeConfig {
        guard let data = defaults.data(forKey: StorageKey.nudgeConfig),
              let decoded = try? decoder.decode(NudgeConfig.self, from: data)
        else { return .default }
        return decoded
    }

    static func saveNudgeConfig(_ config: NudgeConfig) {
        defaults.set(try? encoder.encode(config), forKey: StorageKey.nudgeConfig)
    }
}
