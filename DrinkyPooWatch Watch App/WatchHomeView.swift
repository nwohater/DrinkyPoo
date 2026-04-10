import SwiftUI
import SwiftData

struct WatchHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayEntry.date) private var entries: [DayEntry]

    private var snapshot: DrinkyPooStatsSnapshot {
        DrinkyPooStatsCalculator.makeSnapshot(entries: entries)
    }

    var body: some View {
        List {
            statusSection
            streakSection
            historySection
        }
        .navigationTitle("Today")
    }

    private var statusSection: some View {
        Section("Log Today") {
            Button {
                upsertToday(state: .dry)
            } label: {
                selectionRow(title: "Dry Day", state: .dry, tint: .green)
            }
            .tint(.green)

            Button {
                upsertToday(state: .drinking)
            } label: {
                selectionRow(title: "Drinking Day", state: .drinking, tint: .orange)
            }
            .tint(.orange)

            if snapshot.todayState != nil {
                Button("Clear Log", role: .destructive) {
                    removeToday()
                }
            }

            LabeledContent("Status", value: todayStatusLabel)
            LabeledContent("YTD Dry", value: String(format: "%.0f%%", snapshot.ytdDryPercent))
        }
    }

    private var streakSection: some View {
        Section("Streaks") {
            LabeledContent("Dry", value: "\(snapshot.currentDryStreak)d")
            LabeledContent("Drinking", value: "\(snapshot.currentDrinkingStreak)d")
        }
    }

    private var historySection: some View {
        Section("Last 7 Days") {
            ForEach(snapshot.last7Days, id: \.date) { day in
                HStack {
                    Text(day.date.formatted(.dateTime.weekday(.abbreviated)))
                    Spacer()
                    Text(label(for: day.state))
                        .foregroundStyle(color(for: day.state))
                }
            }
        }
    }

    private var todayStatusLabel: String {
        label(for: snapshot.todayState)
    }

    private func selectionRow(title: String, state: DayState, tint: Color) -> some View {
        HStack {
            Text(title)
            Spacer()
            if snapshot.todayState == state {
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(tint)
            }
        }
    }

    private func label(for state: DayState?) -> String {
        switch state {
        case .dry:
            return "Dry"
        case .drinking:
            return "Drinking"
        case .none:
            return "Unlogged"
        }
    }

    private func color(for state: DayState?) -> Color {
        switch state {
        case .dry:
            return .green
        case .drinking:
            return .orange
        case .none:
            return .secondary
        }
    }

    private func upsertToday(state: DayState) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let existing = entries.first(where: { calendar.startOfDay(for: $0.date) == today }) {
            existing.state = state
        } else {
            modelContext.insert(DayEntry(date: today, state: state))
        }
    }

    private func removeToday() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let existing = entries.first(where: { calendar.startOfDay(for: $0.date) == today }) else {
            return
        }

        modelContext.delete(existing)
    }
}

#Preview {
    WatchHomeView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
