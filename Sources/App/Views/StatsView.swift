import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        StatCard(title: "Current streak",
                                 value: "\(appState.currentStreak)",
                                 unit: appState.currentStreak == 1 ? "day" : "days",
                                 systemImage: "flame.fill",
                                 tint: .orange)
                        StatCard(title: "Total focused",
                                 value: focusedValue,
                                 unit: focusedUnit,
                                 systemImage: "hourglass",
                                 tint: .accentColor)
                    }
                    HStack(spacing: 12) {
                        StatCard(title: "Sessions",
                                 value: "\(appState.completedSessions.count)",
                                 unit: "completed",
                                 systemImage: "checkmark.seal.fill",
                                 tint: .green)
                        StatCard(title: "Time reclaimed",
                                 value: reclaimedValue,
                                 unit: reclaimedUnit,
                                 systemImage: "arrow.uturn.backward.circle.fill",
                                 tint: .purple)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last 7 days").font(.headline)
                        Chart(appState.last7Days) { day in
                            BarMark(
                                x: .value("Day", day.date, unit: .day),
                                y: .value("Minutes", day.minutes)
                            )
                            .foregroundStyle(Color.accentColor.gradient)
                            .cornerRadius(6)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day)) { value in
                                AxisValueLabel(format: .dateTime.weekday(.narrow))
                            }
                        }
                        .frame(height: 180)
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    if appState.history.isEmpty {
                        Text("Finish your first focus session to start building stats.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats")
        }
    }

    private var focusedValue: String {
        let m = appState.totalFocusedMinutes
        return m >= 60 ? String(format: "%.1f", Double(m) / 60) : "\(m)"
    }
    private var focusedUnit: String { appState.totalFocusedMinutes >= 60 ? "hours" : "min" }

    // A simple "time reclaimed" estimate = total focused time.
    private var reclaimedValue: String { focusedValue }
    private var reclaimedUnit: String { focusedUnit }
}

private struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let systemImage: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
            Text(value)
                .font(.system(size: 30, weight: .bold, design: .rounded))
            Text("\(title) · \(unit)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
