import Foundation
import SwiftData

@Model
final class DayEntry {
    /// Normalized to midnight in the user's calendar.
    /// Uniqueness enforced in AppViewModel.upsertDay — @Attribute(.unique)
    /// is incompatible with CloudKit-backed SwiftData.
    var date: Date = Date.distantPast
    /// Stored as String so SwiftData + CloudKit handles it without any
    /// Codable serialization edge cases.
    var stateRaw: String = DayState.dry.rawValue
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    /// Convenience accessor — converts to/from the typed enum.
    @Transient
    var state: DayState {
        get { DayState(rawValue: stateRaw) ?? .dry }
        set { stateRaw = newValue.rawValue; updatedAt = Date() }
    }

    init(date: Date, state: DayState) {
        self.date = Calendar.current.startOfDay(for: date)
        self.stateRaw = state.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}
