import Foundation
import UserNotifications

/// Schedules ordinary local notifications ("guilt nudges") and focus-session
/// alerts. Requires no Screen Time entitlement — works on any account.
@MainActor
final class NudgeManager: ObservableObject {

    @Published private(set) var authorized = false
    @Published var config: NudgeConfig

    private let center = UNUserNotificationCenter.current()
    private let nudgePrefix = "tc.nudge."
    private let daysAhead = 7

    init() {
        config = SharedStore.loadNudgeConfig()
    }

    func refreshAuthorization() async {
        let settings = await center.notificationSettings()
        authorized = settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        await refreshAuthorization()
        return granted
    }

    // MARK: - Scheduled guilt nudges

    func update(config newConfig: NudgeConfig) async {
        config = newConfig
        SharedStore.saveNudgeConfig(newConfig)
        await rescheduleNudges()
    }

    /// Cancels and re-plants all guilt nudges for the next few days.
    /// Repeating triggers can't vary their text, so we schedule discrete
    /// notifications with fresh random messages and refresh them on launch.
    func rescheduleNudges() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(nudgePrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ids)

        guard config.enabled, !config.minutesOfDay.isEmpty else { return }
        if !authorized { _ = await requestAuthorization() }
        guard authorized else { return }

        let cal = Calendar.current
        let now = Date()

        for dayOffset in 0..<daysAhead {
            guard let base = cal.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            for minute in config.minutesOfDay {
                var comps = cal.dateComponents([.year, .month, .day], from: base)
                comps.hour = minute / 60
                comps.minute = minute % 60
                guard let fireDate = cal.date(from: comps), fireDate > now else { continue }

                let content = UNMutableNotificationContent()
                content.title = "TimeControl"
                content.body = NudgeMessages.randomNotification
                content.sound = .default

                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                    repeats: false
                )
                let request = UNNotificationRequest(
                    identifier: "\(nudgePrefix)\(Int(fireDate.timeIntervalSince1970))",
                    content: content,
                    trigger: trigger
                )
                try? await center.add(request)
            }
        }
    }

    func sendTestNudge() async {
        if !authorized { _ = await requestAuthorization() }
        guard authorized else { return }
        let content = UNMutableNotificationContent()
        content.title = "TimeControl"
        content.body = NudgeMessages.randomNotification
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
        try? await center.add(UNNotificationRequest(identifier: "tc.nudge.test", content: content, trigger: trigger))
    }
}
