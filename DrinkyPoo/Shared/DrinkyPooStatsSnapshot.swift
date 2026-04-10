import Foundation

struct DrinkyPooStatsSnapshot {
    let todayState: DayState?
    let currentDryStreak: Int
    let currentDrinkingStreak: Int
    let ytdDryPercent: Double
    let ytdDryCount: Int
    let ytdLoggedCount: Int
    let last7Days: [(date: Date, state: DayState?)]
}

enum DrinkyPooStatsCalculator {
    static func makeSnapshot(
        entries: [DayEntry],
        calendar: Calendar = .current,
        now: Date = Date()
    ) -> DrinkyPooStatsSnapshot {
        let today = calendar.startOfDay(for: now)
        let lookup = Dictionary(uniqueKeysWithValues: entries.map {
            (calendar.startOfDay(for: $0.date), $0.state)
        })

        let year = calendar.component(.year, from: now)
        let ytdEntries = entries.filter { calendar.component(.year, from: $0.date) == year }
        let ytdDryCount = ytdEntries.filter { $0.state == .dry }.count
        let ytdLoggedCount = ytdEntries.count
        let ytdDryPercent = ytdLoggedCount > 0
            ? Double(ytdDryCount) / Double(ytdLoggedCount) * 100
            : 0

        let last7Days = (0..<7).reversed().map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            return (date: date, state: lookup[date])
        }

        return DrinkyPooStatsSnapshot(
            todayState: lookup[today],
            currentDryStreak: streakCount(for: .dry, lookup: lookup, calendar: calendar, today: today),
            currentDrinkingStreak: streakCount(for: .drinking, lookup: lookup, calendar: calendar, today: today),
            ytdDryPercent: ytdDryPercent,
            ytdDryCount: ytdDryCount,
            ytdLoggedCount: ytdLoggedCount,
            last7Days: last7Days
        )
    }

    private static func streakCount(
        for targetState: DayState,
        lookup: [Date: DayState],
        calendar: Calendar,
        today: Date
    ) -> Int {
        var count = 0
        var date = today

        if lookup[date] == nil {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: date) else {
                return 0
            }
            date = yesterday
        }

        while lookup[date] == targetState {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: date) else {
                break
            }
            date = previous
        }

        return count
    }
}
