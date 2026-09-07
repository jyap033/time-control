import DeviceActivity
import ManagedSettings
import Foundation

/// Runs out-of-process. iOS wakes it at the start/end of each monitored interval
/// so shields are applied/removed on schedule even when the main app isn't running.
///
/// Convention: the `ManagedSettingsStore` is named by the activity's raw value, and
/// the `FamilyActivitySelection` to shield is stored under that same key. This keeps
/// overlapping schedules and sessions fully isolated from each other.
final class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        let id = activity.rawValue
        guard let selection = SharedStore.selection(for: id) else { return }
        ShieldController.apply(selection, storeName: ManagedSettingsStore.Name(id))
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        let id = activity.rawValue
        ShieldController.clear(storeName: ManagedSettingsStore.Name(id))

        if id == ActivityID.focusSession {
            finishActiveSession()
        }
    }

    /// Record the just-finished on-demand session so the app's stats stay correct
    /// even if the session ended while the app was closed.
    private func finishActiveSession() {
        guard let active = SharedStore.loadActiveSession() else { return }
        let record = SessionRecord(
            id: active.id,
            startDate: active.startDate,
            endDate: active.endDate,
            plannedMinutes: active.plannedMinutes,
            completed: true,
            wasStrict: active.isStrict
        )
        SharedStore.appendHistory(record)
        SharedStore.saveActiveSession(nil)
    }
}
