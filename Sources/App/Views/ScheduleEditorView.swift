import SwiftUI
import FamilyControls

struct ScheduleEditorView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let existing: BlockSchedule?

    @State private var name: String
    @State private var selection: FamilyActivitySelection
    @State private var weekdays: Set<Int>
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var showPicker = false

    private let weekdaySymbols = Calendar.current.shortWeekdaySymbols // index 0 = Sunday

    init(existing: BlockSchedule?) {
        self.existing = existing
        let cal = Calendar.current
        if let existing {
            _name = State(initialValue: existing.name)
            _selection = State(initialValue: existing.selection)
            _weekdays = State(initialValue: existing.weekdays)
            _startDate = State(initialValue: cal.date(from: DateComponents(hour: existing.startHour, minute: existing.startMinute)) ?? Date())
            _endDate = State(initialValue: cal.date(from: DateComponents(hour: existing.endHour, minute: existing.endMinute)) ?? Date())
        } else {
            _name = State(initialValue: "")
            _selection = State(initialValue: FamilyActivitySelection())
            _weekdays = State(initialValue: [2, 3, 4, 5, 6]) // Mon–Fri
            _startDate = State(initialValue: cal.date(from: DateComponents(hour: 9, minute: 0)) ?? Date())
            _endDate = State(initialValue: cal.date(from: DateComponents(hour: 17, minute: 0)) ?? Date())
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Work hours", text: $name)
                }

                Section("Apps to block") {
                    Button {
                        showPicker = true
                    } label: {
                        HStack {
                            Label("Choose apps", systemImage: "apps.iphone")
                            Spacer()
                            Text(selection.summaryText).foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Time") {
                    DatePicker("Start", selection: $startDate, displayedComponents: .hourAndMinute)
                    DatePicker("End", selection: $endDate, displayedComponents: .hourAndMinute)
                }

                Section("Repeat") {
                    HStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { day in
                            DayToggle(
                                label: String(weekdaySymbols[day - 1].prefix(1)),
                                isOn: weekdays.contains(day)
                            ) {
                                if weekdays.contains(day) { weekdays.remove(day) }
                                else { weekdays.insert(day) }
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle(existing == nil ? "New Schedule" : "Edit Schedule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showPicker) {
                AppPickerView(selection: $selection)
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && !weekdays.isEmpty
            && selection.itemCount > 0
    }

    private func save() {
        let cal = Calendar.current
        let start = cal.dateComponents([.hour, .minute], from: startDate)
        let end = cal.dateComponents([.hour, .minute], from: endDate)

        var schedule = existing ?? BlockSchedule(
            name: name, weekdays: weekdays,
            startHour: 9, startMinute: 0, endHour: 17, endMinute: 0
        )
        schedule.name = name
        schedule.weekdays = weekdays
        schedule.startHour = start.hour ?? 9
        schedule.startMinute = start.minute ?? 0
        schedule.endHour = end.hour ?? 17
        schedule.endMinute = end.minute ?? 0
        schedule.selection = selection

        appState.upsert(schedule)
        dismiss()
    }
}

private struct DayToggle: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.bold())
                .frame(width: 36, height: 36)
                .background(isOn ? Color.accentColor : Color.secondary.opacity(0.15))
                .foregroundStyle(isOn ? Color.white : Color.primary)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
