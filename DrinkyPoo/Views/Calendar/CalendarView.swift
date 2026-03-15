import SwiftUI
import SwiftData

// MARK: - CalendarView

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayEntry.date) private var entries: [DayEntry]

    @State private var editDay: EditDay?

    private var entryLookup: [Date: DayState] {
        let cal = Calendar.current
        return Dictionary(uniqueKeysWithValues: entries.map {
            (cal.startOfDay(for: $0.date), $0.state)
        })
    }

    /// All months from January of the current year through today, newest first.
    private var months: [Date] {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        let currentMonth = cal.component(.month, from: now)
        return (1...currentMonth).compactMap { month in
            cal.date(from: DateComponents(year: year, month: month, day: 1))
        }.reversed()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(months, id: \.self) { monthStart in
                    MonthGridView(
                        monthStart: monthStart,
                        entryLookup: entryLookup,
                        onDayTap: { date in
                            editDay = EditDay(date: date)
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .navigationTitle("Calendar")
        .onChange(of: entries) { _, newEntries in
            checkDryMilestone(entries: newEntries)
        }
        .sheet(item: $editDay) { item in
            let key = Calendar.current.startOfDay(for: item.date)
            DayEditSheet(
                date: item.date,
                currentState: entryLookup[key],
                onLog: { state in upsert(date: item.date, state: state) },
                onRemove: { remove(date: item.date) }
            )
            .presentationDetents([.height(300)])
            .presentationCornerRadius(20)
        }
    }

    private func upsert(date: Date, state: DayState) {
        let cal = Calendar.current
        let normalized = cal.startOfDay(for: date)
        if let existing = entries.first(where: { cal.startOfDay(for: $0.date) == normalized }) {
            existing.state = state
        } else {
            modelContext.insert(DayEntry(date: normalized, state: state))
        }
    }

    private func remove(date: Date) {
        let cal = Calendar.current
        let normalized = cal.startOfDay(for: date)
        if let existing = entries.first(where: { cal.startOfDay(for: $0.date) == normalized }) {
            modelContext.delete(existing)
        }
    }

}

// Identifiable wrapper so .sheet(item:) always has data when the sheet renders.
private struct EditDay: Identifiable {
    let id = UUID()
    let date: Date
}

// MARK: - MonthGridView

private struct MonthGridView: View {
    let monthStart: Date
    let entryLookup: [Date: DayState]
    let onDayTap: (Date) -> Void

    private let cal = Calendar.current

    /// Cells grouped into rows of 7. nil = empty padding cell.
    private var weeks: [[Int?]] {
        var cells: [Int?] = Array(repeating: nil, count: firstWeekdayOffset)
        cells += (1...daysInMonth).map { Optional($0) }
        while cells.count % 7 != 0 { cells.append(nil) }
        return stride(from: 0, to: cells.count, by: 7).map { Array(cells[$0..<$0+7]) }
    }

    /// Weekday header symbols starting from the locale's first weekday.
    private var weekdayHeaders: [String] {
        let symbols = cal.veryShortWeekdaySymbols // ["S","M","T","W","T","F","S"] in en-US
        let offset = cal.firstWeekday - 1
        return Array(symbols[offset...]) + Array(symbols[..<offset])
    }

    /// Number of leading empty cells before day 1.
    private var firstWeekdayOffset: Int {
        let weekday = cal.component(.weekday, from: monthStart)
        return (weekday - cal.firstWeekday + 7) % 7
    }

    private var daysInMonth: Int {
        cal.range(of: .day, in: .month, for: monthStart)!.count
    }

    private func date(for day: Int) -> Date {
        cal.date(from: DateComponents(
            year: cal.component(.year, from: monthStart),
            month: cal.component(.month, from: monthStart),
            day: day
        ))!
    }

    private func cellState(for date: Date) -> DayCellState {
        let today = cal.startOfDay(for: Date())
        let normalized = cal.startOfDay(for: date)

        if normalized > today { return .future }

        switch entryLookup[normalized] {
        case .dry:       return .dry
        case .drinking:  return .drinking
        case .none:
            return cal.isDateInToday(date) ? .todayUnlogged : .unloggedPast
        }
    }

    private var monthlySummary: String {
        let month = cal.component(.month, from: monthStart)
        let year  = cal.component(.year,  from: monthStart)
        let today = cal.startOfDay(for: Date())

        let relevant = entryLookup.filter { (d, _) in
            cal.component(.month, from: d) == month &&
            cal.component(.year,  from: d) == year &&
            d <= today
        }
        let dry      = relevant.values.filter { $0 == .dry }.count
        let drinking = relevant.values.filter { $0 == .drinking }.count
        let total    = dry + drinking
        guard total > 0 else {
            return "\(monthStart.formatted(.dateTime.month(.wide))): no days logged"
        }
        let pct = Int(Double(dry) / Double(total) * 100)
        return "\(monthStart.formatted(.dateTime.month(.wide))): \(dry) dry / \(drinking) drinking — \(pct)%"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Month + year header
            Text(monthStart, format: .dateTime.month(.wide).year())
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))
                .padding(.horizontal, 4)

            Grid(horizontalSpacing: 4, verticalSpacing: 4) {
                // Weekday header row
                GridRow {
                    ForEach(Array(weekdayHeaders.enumerated()), id: \.offset) { _, symbol in
                        Text(symbol)
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(Color("SecondaryText"))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Week rows
                ForEach(Array(weeks.enumerated()), id: \.offset) { _, week in
                    GridRow {
                        ForEach(Array(week.enumerated()), id: \.offset) { _, day in
                            if let day {
                                let d = date(for: day)
                                let state = cellState(for: d)
                                DayCellView(day: day, state: state)
                                    .onTapGesture {
                                        guard state != .future else { return }
                                        onDayTap(d)
                                    }
                            } else {
                                Color.clear.frame(height: 36)
                            }
                        }
                    }
                }
            }

            // Monthly summary
            Text(monthlySummary)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
                .padding(.horizontal, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
        )
    }
}

// MARK: - DayCellState

enum DayCellState {
    case dry
    case drinking
    case unloggedPast
    case todayUnlogged
    case future
}

// MARK: - DayCellView

private struct DayCellView: View {
    let day: Int
    let state: DayCellState

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            background
            Text("\(day)")
                .font(.system(size: 13, weight: state == .todayUnlogged ? .bold : .regular))
                .foregroundStyle(textColor)
        }
        .frame(height: 36)
    }

    @ViewBuilder
    private var background: some View {
        switch state {
        case .dry:
            RoundedRectangle(cornerRadius: 8).fill(Color("DryDayColor"))
        case .drinking:
            RoundedRectangle(cornerRadius: 8).fill(Color("DrinkingDayColor"))
        case .unloggedPast:
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.orange.opacity(0.55), lineWidth: 1.5)
        case .todayUnlogged:
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color("AccentBlue"), lineWidth: 2)
        case .future:
            Color.clear
        }
    }

    private var textColor: Color {
        switch state {
        case .dry, .drinking:   return .white
        case .unloggedPast:     return Color.orange.opacity(0.8)
        case .todayUnlogged:    return Color("AccentBlue")
        case .future:           return Color("SecondaryText").opacity(0.3)
        }
    }
}

// MARK: - Preview

#Preview {
    CalendarView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
