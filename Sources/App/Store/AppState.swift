import Foundation
import Combine
import FamilyControls
import DeviceActivity
import ManagedSettings

/// One day's total focused minutes, for the stats chart.
struct DayStat: Identifiable {
    let date: Date
    let minutes: Int
    var id: Date { date }
}

/// The app's single source of truth. Owns focus sessions, schedules and stats,
/// and bridges the SwiftUI layer to DeviceActivity / ManagedSettings.
@MainActor
final class AppState: ObservableObject {

    @Published var activeSession: ActiveSession?
    @Published var schedules: [BlockSchedule] = []
    @Published var history: [SessionRecord] = []
    @Published var strictModeDefault: Bool

    private let center = DeviceActivityCenter()
    private var ticker: AnyCancellable?

    init() {
        strictModeDefault = SharedStore.strictModeDefault
        schedules = SharedStore.loadSchedules()
        history = SharedStore.loadHistory()
        reconcileActiveSession()
        if activeSession != nil { startTicking() }
    }

    // MARK: - Focus sessions

    func startFocusSession(selection: FamilyActivitySelection, minutes: Int, strict: Bool) {
        let now = Date()
        let end = now.addingTimeInterval(TimeInterval(minutes * 60))
        let selectionData = try? JSONEncoder().encode(selection)

        let session = ActiveSession(
            startDate: now,
            endDate: end,
            plannedMinutes: minutes,
            isStrict: strict,
            selectionData: selectionData
        )

        SharedStore.saveActiveSession(session)
        SharedStore.saveSelection(selection, for: ActivityID.focusSession)
        ShieldController.apply(selection, storeName: ManagedSettingsStore.Name(ActivityID.focusSession))

        // Backstop so the shield lifts even if the app is killed (>= 15 min sessions).
        let schedule = DeviceActivitySchedule(
            intervalStart: timeComponents(now),
            intervalEnd: timeComponents(end),
            repeats: false
        )
        try? center.startMonitoring(DeviceActivityName(ActivityID.focusSession), during: schedule)

        activeSession = session
        startTicking()
    }

    /// End the running session. `completed` = ran to the end vs. user stopped early.
    func endFocusSession(completed: Bool) {
        guard let active = activeSession else { return }
        center.stopMonitoring([DeviceActivityName(ActivityID.focusSession)])
        ShieldController.clear(storeName: ManagedSettingsStore.Name(ActivityID.focusSession))

        let record = SessionRecord(
            id: active.id,
            startDate: active.startDate,
            endDate: completed ? active.endDate : Date(),
            plannedMinutes: active.plannedMinutes,
            completed: completed,
            wasStrict: active.isStrict
        )
        SharedStore.appendHistory(record)
        SharedStore.saveActiveSession(nil)

        activeSession = nil
        history = SharedStore.loadHistory()
        stopTicking()
    }

    /// True when the user is allowed to stop the current session right now.
    var canEndEarly: Bool {
        guard let active = activeSession else { return false }
        return !active.isStrict
    }

    private func reconcileActiveSession() {
        activeSession = SharedStore.loadActiveSession()
        // The monitor may have finished it while the app was closed, or a short
        // session may have elapsed with no backstop — finalize it now.
        if let active = activeSession, active.isFinished {
            endFocusSession(completed: true)
        }
    }

    private func startTicking() {
        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let active = self.activeSession else { return }
                if active.isFinished { self.endFocusSession(completed: true) }
                else { self.objectWillChange.send() }
            }
    }

    private func stopTicking() {
        ticker?.cancel()
        ticker = nil
    }

    // MARK: - Schedules

    func upsert(_ schedule: BlockSchedule) {
        if let idx = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[idx] = schedule
        } else {
            schedules.append(schedule)
        }
        persistAndSyncSchedules()
    }

    func deleteSchedules(at offsets: IndexSet) {
        schedules.remove(atOffsets: offsets)
        persistAndSyncSchedules()
    }

    func setScheduleEnabled(_ schedule: BlockSchedule, enabled: Bool) {
        guard let idx = schedules.firstIndex(where: { $0.id == schedule.id }) else { return }
        schedules[idx].isEnabled = enabled
        persistAndSyncSchedules()
    }

    private func persistAndSyncSchedules() {
        SharedStore.saveSchedules(schedules)
        syncScheduleMonitoring()
    }

    /// Re-registers all schedule monitoring windows with DeviceActivity.
    func syncScheduleMonitoring() {
        let existing = center.activities.filter { $0.rawValue.hasPrefix("tc.sched.") }
        center.stopMonitoring(existing)
        for name in existing {
            ShieldController.clear(storeName: ManagedSettingsStore.Name(name.rawValue))
        }

        for schedule in schedules where schedule.isEnabled {
            for weekday in schedule.weekdays {
                let id = schedule.activityID(weekday: weekday)
                SharedStore.saveSelection(schedule.selection, for: id)
                let window = DeviceActivitySchedule(
                    intervalStart: schedule.startComponents(weekday: weekday),
                    intervalEnd: schedule.endComponents(weekday: weekday),
                    repeats: true
                )
                try? center.startMonitoring(DeviceActivityName(id), during: window)
            }
        }
    }

    // MARK: - Settings

    func setStrictModeDefault(_ on: Bool) {
        strictModeDefault = on
        SharedStore.strictModeDefault = on
    }

    // MARK: - Stats

    var completedSessions: [SessionRecord] { history.filter { $0.completed } }

    var totalFocusedMinutes: Int {
        history.reduce(0) { $0 + $1.actualMinutes }
    }

    var currentStreak: Int {
        let cal = Calendar.current
        let days = Set(history.map { cal.startOfDay(for: $0.startDate) })
        guard !days.isEmpty else { return 0 }
        var streak = 0
        var day = cal.startOfDay(for: Date())
        // Allow the streak to still count if nothing today but there was yesterday.
        if !days.contains(day) { day = cal.date(byAdding: .day, value: -1, to: day)! }
        while days.contains(day) {
            streak += 1
            day = cal.date(byAdding: .day, value: -1, to: day)!
        }
        return streak
    }

    /// Focused minutes per day for the last 7 days (oldest first), for the chart.
    var last7Days: [DayStat] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let day = cal.date(byAdding: .day, value: -offset, to: today)!
            let minutes = history
                .filter { cal.isDate($0.startDate, inSameDayAs: day) }
                .reduce(0) { $0 + $1.actualMinutes }
            return DayStat(date: day, minutes: minutes)
        }
    }

    // MARK: - Helpers

    private func timeComponents(_ date: Date) -> DateComponents {
        Calendar.current.dateComponents([.hour, .minute, .second], from: date)
    }
}
