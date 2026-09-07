import SwiftUI

struct SchedulesView: View {
    @EnvironmentObject private var appState: AppState
    @State private var editing: BlockSchedule?
    @State private var showEditor = false

    var body: some View {
        NavigationStack {
            List {
                if appState.schedules.isEmpty {
                    ContentUnavailableCompat(
                        title: "No schedules yet",
                        systemImage: "calendar.badge.plus",
                        description: "Create a recurring block — like work hours or bedtime — and TimeControl will shield your apps automatically."
                    )
                } else {
                    ForEach(appState.schedules) { schedule in
                        Button {
                            editing = schedule
                            showEditor = true
                        } label: {
                            ScheduleRow(schedule: schedule)
                        }
                        .tint(.primary)
                    }
                    .onDelete { appState.deleteSchedules(at: $0) }
                }
            }
            .navigationTitle("Schedules")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editing = nil
                        showEditor = true
                    } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showEditor) {
                ScheduleEditorView(existing: editing)
            }
        }
    }
}

private struct ScheduleRow: View {
    @EnvironmentObject private var appState: AppState
    let schedule: BlockSchedule

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(schedule.name).font(.headline)
                Text("\(schedule.timeRangeText) · \(schedule.weekdaysText)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(schedule.selection.summaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: Binding(
                get: { schedule.isEnabled },
                set: { appState.setScheduleEnabled(schedule, enabled: $0) }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 4)
    }
}

/// Small back-compat stand-in for `ContentUnavailableView` (iOS 17+).
struct ContentUnavailableCompat: View {
    let title: String
    let systemImage: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowSeparator(.hidden)
    }
}
