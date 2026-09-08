import Foundation
import FamilyControls

/// A recurring, scheduled block (e.g. "Work 9–5", "Bedtime").
struct BlockSchedule: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var name: String
    /// Days the schedule is active. 1 = Sunday ... 7 = Saturday (Calendar convention).
    var weekdays: Set<Int>
    var startHour: Int
    var startMinute: Int
    var endHour: Int
    var endMinute: Int
    var isEnabled: Bool = true
    /// Encoded `FamilyActivitySelection` (tokens are opaque + Codable).
    var selectionData: Data?

    var selection: FamilyActivitySelection {
        get {
            guard let selectionData,
                  let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData)
            else { return FamilyActivitySelection() }
            return decoded
        }
        set { selectionData = try? JSONEncoder().encode(newValue) }
    }

    /// The monitored DeviceActivity id for a given weekday.
    func activityID(weekday: Int) -> String {
        ActivityID.schedule(id.uuidString, weekday: weekday)
    }

    /// All monitored activity ids for this schedule (one per enabled weekday).
    var activityIDs: [String] {
        weekdays.map { activityID(weekday: $0) }
    }

    func startComponents(weekday: Int) -> DateComponents {
        DateComponents(weekday: weekday, hour: startHour, minute: startMinute)
    }
    func endComponents(weekday: Int) -> DateComponents {
        DateComponents(weekday: weekday, hour: endHour, minute: endMinute)
    }

    var timeRangeText: String {
        String(format: "%02d:%02d – %02d:%02d", startHour, startMinute, endHour, endMinute)
    }

    var weekdaysText: String {
        let symbols = Calendar.current.shortWeekdaySymbols // ["Sun", ...] index 0..6
        if weekdays.count == 7 { return "Every day" }
        let sorted = weekdays.sorted()
        return sorted.compactMap { symbols[safe: $0 - 1] }.joined(separator: " ")
    }
}

/// A single completed or in-progress focus session, used for stats + streaks.
struct SessionRecord: Codable, Identifiable, Equatable {
    var id: UUID = UUID()
    var startDate: Date
    var endDate: Date
    var plannedMinutes: Int
    var completed: Bool           // ran to the end vs. ended early
    var wasStrict: Bool

    var actualMinutes: Int {
        max(0, Int(endDate.timeIntervalSince(startDate) / 60))
    }
}

/// The currently-running on-demand focus session (persisted so the timer + shield
/// survive the app being backgrounded or killed).
struct ActiveSession: Codable, Equatable {
    var id: UUID = UUID()
    var startDate: Date
    var endDate: Date
    var plannedMinutes: Int
    var isStrict: Bool
    var selectionData: Data?

    var selection: FamilyActivitySelection {
        guard let selectionData,
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData)
        else { return FamilyActivitySelection() }
        return decoded
    }

    var remaining: TimeInterval { max(0, endDate.timeIntervalSinceNow) }
    var isFinished: Bool { Date() >= endDate }
}

/// Configuration for scheduled "guilt" notifications (works without any
/// Screen Time entitlement — these are ordinary local notifications).
struct NudgeConfig: Codable, Equatable {
    var enabled: Bool = false
    /// Times of day to fire, stored as minutes-since-midnight (0...1439).
    var minutesOfDay: [Int] = [12 * 60, 15 * 60, 21 * 60] // noon, 3pm, 9pm

    static let `default` = NudgeConfig()
}

extension Int {
    /// Formats a minutes-since-midnight value as "HH:mm".
    var asClockString: String {
        String(format: "%02d:%02d", self / 60, self % 60)
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
