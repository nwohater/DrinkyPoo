import SwiftUI
import SwiftData
import Charts

// MARK: - TrendsView

struct TrendsView: View {
    @Query(sort: \DayEntry.date) private var entries: [DayEntry]
    @AppStorage("goalPercent") private var goalPercent: Double = 50.0

    @State private var viewModel = AppViewModel()
    @State private var selectedMonthAbbrev: String?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                annualBarChartCard
                streakTimelineCard
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .navigationTitle("Trends")
        .onChange(of: entries) { _, new in
            viewModel.update(entries: new)
            viewModel.goalPercent = goalPercent
        }
        .onAppear {
            viewModel.update(entries: entries)
            viewModel.goalPercent = goalPercent
        }
    }

    // MARK: - Annual bar chart

    private var annualBarChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("This Year")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))
            barTooltip
            barChart
            HStack(spacing: 16) {
                legendDot(color: Color("DryDayColor"),      label: "Dry")
                legendDot(color: Color("DrinkingDayColor"), label: "Drinking")
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var barTooltip: some View {
        if let abbrev = selectedMonthAbbrev,
           let entry = barEntries.first(where: { $0.monthAbbrev == abbrev && $0.series == "Dry" }),
           let data = viewModel.monthlyBreakdown[entry.monthIndex] {
            let total = data.dry + data.drinking
            let pct = total > 0 ? Int(Double(data.dry) / Double(total) * 100) : 0
            Text("\(abbrev): \(data.dry) dry / \(data.drinking) drinking — \(pct)%")
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        }
    }

    private var barChart: some View {
        Chart {
            ForEach(barEntries, id: \.id) { entry in
                BarMark(
                    x: .value("Month", entry.monthAbbrev),
                    y: .value("Days", entry.count)
                )
                .foregroundStyle(entry.series == "Dry"
                    ? Color("DryDayColor")
                    : Color("DrinkingDayColor"))
                .cornerRadius(3)
            }
            RuleMark(y: .value("Goal", goalDaysPerMonth))
                .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [5, 3]))
                .foregroundStyle(Color("ProgressGoalLine").opacity(0.7))
        }
        .chartLegend(.hidden)
        .chartYScale(domain: 0...31)
        .chartYAxis {
            AxisMarks(position: .leading, values: .stride(by: 5)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel()
                    .foregroundStyle(Color("SecondaryText"))
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .foregroundStyle(Color("SecondaryText"))
            }
        }
        .chartXSelection(value: $selectedMonthAbbrev)
        .frame(height: 200)
    }

    // MARK: - Streak timeline

    private var streakTimelineCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Streak History")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            streakTimeline
            topStreaksList
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var streakTimeline: some View {
        if viewModel.allStreaks.isEmpty {
            Text("Log a few days to see your streaks here.")
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        } else {
            StreakChartView(streaks: viewModel.allStreaks, yearStart: yearStart, yearEnd: yearEnd)

            HStack(spacing: 16) {
                legendDot(color: Color("DryDayColor"),      label: "Dry")
                legendDot(color: Color("DrinkingDayColor"), label: "Drinking")
            }
        }
    }
    
    @ViewBuilder
    private var topStreaksList: some View {
        if !viewModel.topDryStreaks.isEmpty {
            Divider()
            Text("Longest Dry Streaks")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("PrimaryText"))
            ForEach(Array(viewModel.topDryStreaks.enumerated()), id: \.element.id) { rank, streak in
                streakRow(rank: rank, streak: streak, color: Color("DryDayColor"))
            }
        }
        if !viewModel.topDrinkingStreaks.isEmpty {
            Divider()
            Text("Longest Drinking Streaks")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("PrimaryText"))
            ForEach(Array(viewModel.topDrinkingStreaks.enumerated()), id: \.element.id) { rank, streak in
                streakRow(rank: rank, streak: streak, color: Color("DrinkingDayColor"))
            }
        }
    }

    private func streakRow(rank: Int, streak: Streak, color: Color) -> some View {
        HStack {
            Text("#\(rank + 1)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color("SecondaryText"))
                .frame(width: 28, alignment: .leading)
            Text(streakDateRange(streak))
                .font(.caption)
                .foregroundStyle(Color("PrimaryText"))
            Spacer()
            Text("\(streak.length)d")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(color)
        }
    }

    // MARK: - Helpers

    private var barEntries: [BarEntry] {
        let symbols = Calendar.current.shortMonthSymbols
        var result: [BarEntry] = []
        for month in 1...12 {
            let data = viewModel.monthlyBreakdown[month] ?? (dry: 0, drinking: 0)
            let abbrev = String(symbols[month - 1].prefix(3))
            result.append(BarEntry(monthAbbrev: abbrev, monthIndex: month, count: data.dry,      series: "Dry"))
            result.append(BarEntry(monthAbbrev: abbrev, monthIndex: month, count: data.drinking, series: "Drinking"))
        }
        return result
    }

    private var goalDaysPerMonth: Double { goalPercent / 100.0 * 30.0 }

    private var yearStart: Date {
        let cal = Calendar.current
        return cal.date(from: DateComponents(year: cal.component(.year, from: Date()), month: 1,  day: 1))!
    }

    private var yearEnd: Date {
        let cal = Calendar.current
        return cal.date(from: DateComponents(year: cal.component(.year, from: Date()), month: 12, day: 31))!
    }

    private func streakDateRange(_ streak: Streak) -> String {
        let fmt = Date.FormatStyle().month(.abbreviated).day()
        guard streak.length > 1 else { return streak.start.formatted(fmt) }
        return "\(streak.start.formatted(fmt)) – \(streak.end.formatted(fmt))"
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(.caption).foregroundStyle(Color("SecondaryText"))
        }
    }
}

// MARK: - Streak chart view

private struct StreakChartView: View {
    let streaks: [Streak]
    let yearStart: Date
    let yearEnd: Date

    var body: some View {
        VStack(spacing: 2) {
            Canvas { ctx, size in
                let total = yearEnd.timeIntervalSince(yearStart)
                guard total > 0 else { return }
                for streak in streaks {
                    let x = CGFloat(streak.start.timeIntervalSince(yearStart) / total) * size.width
                    let endDate = Calendar.current.date(byAdding: .day, value: 1, to: streak.end) ?? streak.end
                    let w = max(CGFloat(endDate.timeIntervalSince(streak.start) / total) * size.width, 2)
                    let rect = CGRect(x: x, y: 0, width: w, height: size.height)
                    let color: Color = streak.state == .dry ? Color("DryDayColor") : Color("DrinkingDayColor")
                    ctx.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(color))
                }
            }
            .frame(height: 22)

            HStack(spacing: 0) {
                ForEach(1...12, id: \.self) { month in
                    Text(Calendar.current.veryShortMonthSymbols[month - 1])
                        .font(.system(.caption2, design: .default))
                        .foregroundStyle(Color("SecondaryText"))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - Bar entry model

private struct BarEntry: Identifiable {
    let id = UUID()
    let monthAbbrev: String
    let monthIndex: Int
    let count: Int
    let series: String
}

// MARK: - Preview

#Preview {
    TrendsView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
