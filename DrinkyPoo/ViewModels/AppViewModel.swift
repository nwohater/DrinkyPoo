import Foundation
import SwiftData
import Observation

/// Central ViewModel for Drinky Poo.
///
/// Views use `@Query` to fetch entries from SwiftData, then call `update(entries:)`
/// to keep this VM in sync. All stat properties are computed on the fly — nothing
/// is stored in the database beyond the raw DayEntry list.
@Observable
final class AppViewModel {

    // MARK: - Live entry cache (set by views via @Query)

    private(set) var entries: [DayEntry] = []

    // MARK: - User preferences (persisted in UserDefaults via @AppStorage in views)

    var goalPercent: Double = 50.0

    // MARK: - Entry lookup (date → state, O(1) access)

    private var entryLookup: [Date: DayState] {
        let cal = Calendar.current
        return Dictionary(uniqueKeysWithValues: entries.map {
            (cal.startOfDay(for: $0.date), $0.state)
        })
    }

    // MARK: - Update

    func update(entries: [DayEntry]) {
        self.entries = entries
    }

    // MARK: - CRUD

    /// Creates or updates the entry for `date`. If an entry for that day already
    /// exists it updates `state` and `updatedAt`; otherwise inserts a new one.
    func upsertDay(date: Date = Date(), state: DayState, context: ModelContext) {
        let cal = Calendar.current
        let normalizedDate = cal.startOfDay(for: date)

        if let existing = entry(for: normalizedDate) {
            existing.state = state
            existing.updatedAt = Date()
        } else {
            let newEntry = DayEntry(date: normalizedDate, state: state)
            context.insert(newEntry)
        }
    }

    /// Removes the entry for `date`, reverting that day to "unlogged".
    func removeEntry(for date: Date, context: ModelContext) {
        let cal = Calendar.current
        let normalizedDate = cal.startOfDay(for: date)
        if let existing = entry(for: normalizedDate) {
            context.delete(existing)
        }
    }

    /// Returns the DayEntry for a given date, or nil if unlogged.
    func entry(for date: Date) -> DayEntry? {
        let cal = Calendar.current
        let target = cal.startOfDay(for: date)
        return entries.first { cal.startOfDay(for: $0.date) == target }
    }

    // MARK: - Computed stats

    /// Consecutive dry days ending today (or the most recent logged day).
    var currentDryStreak: Int {
        streakCount(for: .dry)
    }

    /// Consecutive drinking days ending today (or the most recent logged day).
    var currentDrinkingStreak: Int {
        streakCount(for: .drinking)
    }

    /// (dry entries logged so far this calendar year) / (days elapsed in year) × 100
    var ytdDryPercent: Double {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let today = cal.startOfDay(for: now)
        // Days elapsed = Jan 1 through today, inclusive
        let daysElapsed = cal.dateComponents([.day], from: startOfYear, to: cal.date(byAdding: .day, value: 1, to: today)!).day ?? 1

        let dryCount = entries.filter { entry in
            cal.component(.year, from: entry.date) == year && entry.state == .dry
        }.count

        return Double(dryCount) / Double(max(daysElapsed, 1)) * 100
    }

    /// ytdDryPercent / goalPercent, clamped to 0...1.
    var progressToGoal: Double {
        min(ytdDryPercent / max(goalPercent, 1), 1.0)
    }

    /// Number of dry days logged so far this calendar year.
    var ytdDryCount: Int {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        return entries.filter {
            cal.component(.year, from: $0.date) == year && $0.state == .dry
        }.count
    }

    /// Number of days elapsed in the current calendar year (Jan 1 through today, inclusive).
    var daysElapsedInYear: Int {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1))!
        let today = cal.startOfDay(for: now)
        return cal.dateComponents([.day], from: startOfYear, to: cal.date(byAdding: .day, value: 1, to: today)!).day ?? 1
    }

    /// Per-month dry/drinking counts for the current year. Keys are 1–12.
    var monthlyBreakdown: [Int: (dry: Int, drinking: Int)] {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        var breakdown: [Int: (dry: Int, drinking: Int)] = Dictionary(uniqueKeysWithValues: (1...12).map { ($0, (dry: 0, drinking: 0)) })

        for entry in entries {
            guard cal.component(.year, from: entry.date) == year else { continue }
            let month = cal.component(.month, from: entry.date)
            var current = breakdown[month] ?? (dry: 0, drinking: 0)
            if entry.state == .dry {
                current = (dry: current.dry + 1, drinking: current.drinking)
            } else {
                current = (dry: current.dry, drinking: current.drinking + 1)
            }
            breakdown[month] = current
        }
        return breakdown
    }

    /// All dry streaks in the current year, sorted longest-first.
    var allDryStreaks: [Streak] {
        buildStreaks(for: .dry)
            .sorted { $0.length > $1.length }
    }

    /// All dry + drinking streaks in the current year, sorted chronologically.
    /// Used by the Trends streak timeline chart.
    var allStreaks: [Streak] {
        (buildStreaks(for: .dry) + buildStreaks(for: .drinking))
            .sorted { $0.start < $1.start }
    }

    /// The top 5 longest dry streaks in the current year.
    var topDryStreaks: [Streak] {
        Array(allDryStreaks.prefix(5))
    }

    // MARK: - Helpers

    private func streakCount(for targetState: DayState) -> Int {
        let cal = Calendar.current
        let lookup = entryLookup
        var count = 0
        var date = cal.startOfDay(for: Date())

        // If today is unlogged, start from yesterday so an un-logged today
        // doesn't erase a streak that was intact through yesterday.
        if lookup[date] == nil {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: date) else { return 0 }
            date = yesterday
        }

        while true {
            guard let state = lookup[date] else { break }
            guard state == targetState else { break }
            count += 1
            guard let previous = cal.date(byAdding: .day, value: -1, to: date) else { break }
            date = previous
        }
        return count
    }

    /// Builds an ordered list of streak blocks for the current year.
    private func buildStreaks(for targetState: DayState) -> [Streak] {
        let cal = Calendar.current
        let year = cal.component(.year, from: Date())
        let lookup = entryLookup

        guard let startOfYear = cal.date(from: DateComponents(year: year, month: 1, day: 1)) else { return [] }
        let today = cal.startOfDay(for: Date())

        var streaks: [Streak] = []
        var streakStart: Date?
        var current = startOfYear

        while current <= today {
            if lookup[current] == targetState {
                if streakStart == nil { streakStart = current }
            } else {
                if let start = streakStart {
                    let end = cal.date(byAdding: .day, value: -1, to: current) ?? current
                    let length = cal.dateComponents([.day], from: start, to: cal.date(byAdding: .day, value: 1, to: end)!).day ?? 0
                    streaks.append(Streak(start: start, end: end, length: length, state: targetState))
                    streakStart = nil
                }
            }
            guard let next = cal.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }

        // Close any open streak at today
        if let start = streakStart {
            let length = cal.dateComponents([.day], from: start, to: cal.date(byAdding: .day, value: 1, to: today)!).day ?? 0
            streaks.append(Streak(start: start, end: today, length: length, state: targetState))
        }

        return streaks
    }
}

// MARK: - Supporting types

struct Streak: Identifiable {
    let id = UUID()
    let start: Date
    let end: Date
    let length: Int
    let state: DayState
}
