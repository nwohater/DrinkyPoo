import SwiftUI

// MARK: - YearSummaryCard

/// A self-contained card view suitable for rendering via ImageRenderer and sharing.
struct YearSummaryCard: View {
    let year: Int
    let entries: [DayEntry]

    private let cal = Calendar.current
    private let monthSymbols = Calendar.current.shortMonthSymbols // ["Jan", "Feb", ...]

    // MARK: Computed stats

    private var yearEntries: [DayEntry] {
        entries.filter { cal.component(.year, from: $0.date) == year }
    }

    private var totalDry: Int { yearEntries.filter { $0.state == .dry }.count }
    private var totalDrinking: Int { yearEntries.filter { $0.state == .drinking }.count }
    private var totalLogged: Int { yearEntries.count }
    private var dryPercent: Double {
        totalLogged > 0 ? Double(totalDry) / Double(totalLogged) * 100 : 0
    }

    private var longestDryStreak: Int { longestStreak(for: .dry) }
    private var longestDrinkingStreak: Int { longestStreak(for: .drinking) }

    private func monthlyStats(month: Int) -> (dry: Int, drinking: Int) {
        let e = yearEntries.filter { cal.component(.month, from: $0.date) == month }
        return (dry: e.filter { $0.state == .dry }.count,
                drinking: e.filter { $0.state == .drinking }.count)
    }

    private func longestStreak(for state: DayState) -> Int {
        guard let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)),
              let endOfYear   = cal.date(from: DateComponents(year: year, month: 12, day: 31)) else { return 0 }

        let lookup = Dictionary(uniqueKeysWithValues: yearEntries.map {
            (cal.startOfDay(for: $0.date), $0.state)
        })
        let end = min(endOfYear, cal.startOfDay(for: Date()))

        var maxStreak = 0
        var current = 0
        var date = startOfYear

        while date <= end {
            if lookup[date] == state {
                current += 1
                maxStreak = max(maxStreak, current)
            } else {
                current = 0
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }
        return maxStreak
    }

    // MARK: Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            statsRow
            Divider()
            streakRow
            Divider()
            monthlyGrid
            Divider()
            footer
        }
        .background(Color("AppBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .frame(width: 360)
    }

    // MARK: - Sections

    private var header: some View {
        HStack(spacing: 12) {
            Image("LaunchIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("Drinky Poo")
                    .font(.headline)
                    .foregroundStyle(Color("PrimaryText"))
                Text("\(String(year)) Year in Review")
                    .font(.subheadline)
                    .foregroundStyle(Color("SecondaryText"))
            }
            Spacer()
        }
        .padding(16)
    }

    private var statsRow: some View {
        HStack(spacing: 0) {
            statCell(value: "\(totalDry)", label: "dry days", color: Color("DryDayColor"))
            Divider().frame(height: 44)
            statCell(value: "\(totalDrinking)", label: "drinking", color: Color("DrinkingDayColor"))
            Divider().frame(height: 44)
            statCell(value: String(format: "%.0f%%", dryPercent), label: "dry rate", color: Color("PrimaryText"))
        }
        .padding(.vertical, 12)
    }

    private func statCell(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var streakRow: some View {
        if longestDryStreak > 0 || longestDrinkingStreak > 0 {
            VStack(alignment: .leading, spacing: 6) {
                if longestDryStreak > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(Color("DryDayColor"))
                        Text("Longest dry streak: \(longestDryStreak) day\(longestDryStreak == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(Color("PrimaryText"))
                    }
                }
                if longestDrinkingStreak > 0 {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .foregroundStyle(Color("DrinkingDayColor"))
                        Text("Longest drinking streak: \(longestDrinkingStreak) day\(longestDrinkingStreak == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(Color("PrimaryText"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }

    private var monthlyGrid: some View {
        VStack(spacing: 6) {
            ForEach(1...12, id: \.self) { month in
                let stats = monthlyStats(month: month)
                let total = stats.dry + stats.drinking
                if total > 0 || cal.component(.month, from: Date()) >= month && cal.component(.year, from: Date()) == year {
                    monthRow(month: month, stats: stats)
                }
            }
        }
        .padding(16)
    }

    private func monthRow(month: Int, stats: (dry: Int, drinking: Int)) -> some View {
        let total = stats.dry + stats.drinking
        let dryRatio = total > 0 ? Double(stats.dry) / Double(total) : 0

        return HStack(spacing: 8) {
            Text(monthSymbols[month - 1])
                .font(.caption.monospacedDigit())
                .foregroundStyle(Color("SecondaryText"))
                .frame(width: 30, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(total > 0 ? Color("DrinkingDayColor").opacity(0.25) : Color.gray.opacity(0.1))
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color("DryDayColor").opacity(total > 0 ? 0.85 : 0))
                        .frame(width: geo.size.width * dryRatio)
                }
            }
            .frame(height: 12)

            if total > 0 {
                Text("\(stats.dry)d / \(stats.drinking)d")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Color("SecondaryText"))
                    .frame(width: 54, alignment: .trailing)
            } else {
                Text("no data")
                    .font(.caption2)
                    .foregroundStyle(Color("SecondaryText").opacity(0.5))
                    .frame(width: 54, alignment: .trailing)
            }
        }
        .frame(height: 16)
    }

    private var footer: some View {
        Text("Tracked with Drinky Poo")
            .font(.caption2)
            .foregroundStyle(Color("SecondaryText").opacity(0.6))
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(10)
    }
}

// MARK: - Share helper

/// Renders the year summary card and presents the system share sheet directly via UIKit,
/// bypassing SwiftUI's sheet mechanism which conflicts with UIActivityViewController.
@MainActor
func shareYearSummary(year: Int, entries: [DayEntry]) {
    let card = YearSummaryCard(year: year, entries: entries)
        .environment(\.colorScheme, .light)
    let renderer = ImageRenderer(content: card)
    renderer.scale = UIScreen.main.scale
    guard let image = renderer.uiImage else { return }

    // Save to a temp file with the desired filename so the share sheet uses it
    let filename = "DP\(String(year)).png"
    let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
    if let data = image.pngData() { try? data.write(to: tempURL) }

    let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

    guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let root = scene.keyWindow?.rootViewController else { return }

    var top = root
    while let presented = top.presentedViewController { top = presented }

    // iPad requires a source rect for the popover
    if let popover = activityVC.popoverPresentationController {
        popover.sourceView = top.view
        popover.sourceRect = CGRect(x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
    }

    top.present(activityVC, animated: true)
}
