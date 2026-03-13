import Foundation
import UserNotifications

/// Manages local daily reminder notifications.
@MainActor
final class NotificationManager {

    static let shared = NotificationManager()
    private init() {}

    private let repeatingID = "com.golackey.DrinkyPoo.dailyReminder"

    // MARK: - Permission

    /// Requests notification authorization. Returns true if granted.
    func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Returns the current authorization status without prompting.
    func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    // MARK: - Scheduling

    /// Schedules (or replaces) a repeating daily reminder at the given hour + minute.
    func scheduleDailyReminder(at time: DateComponents) {
        cancelDailyReminder()

        let content = UNMutableNotificationContent()
        content.title = "Drinky Poo"
        content.body = "Don't forget to log today!"
        content.sound = .default

        var trigger = DateComponents()
        trigger.hour   = time.hour
        trigger.minute = time.minute

        let request = UNNotificationRequest(
            identifier: repeatingID,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Cancels the daily reminder.
    func cancelDailyReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [repeatingID])
    }

    /// Call after a successful day log so the notification doesn't fire again today.
    /// Cancels the repeating trigger and re-schedules starting from tomorrow.
    func suppressTodayNotification(reminderTime: DateComponents?) {
        guard let time = reminderTime else { return }
        cancelDailyReminder()

        // Check whether today's reminder time has already passed.
        let cal = Calendar.current
        let now = Date()
        var todayFire = DateComponents()
        todayFire.year   = cal.component(.year,  from: now)
        todayFire.month  = cal.component(.month, from: now)
        todayFire.day    = cal.component(.day,   from: now)
        todayFire.hour   = time.hour
        todayFire.minute = time.minute
        let fireDate = cal.date(from: todayFire) ?? now

        // If reminder already fired today just reschedule the repeating one for tomorrow
        if fireDate <= now {
            scheduleDailyReminder(at: time)
            return
        }

        // Otherwise skip today by scheduling the repeating trigger starting tomorrow.
        if let tomorrow = cal.date(byAdding: .day, value: 1, to: now) {
            var tomorrowComps = DateComponents()
            tomorrowComps.year   = cal.component(.year,  from: tomorrow)
            tomorrowComps.month  = cal.component(.month, from: tomorrow)
            tomorrowComps.day    = cal.component(.day,   from: tomorrow)
            tomorrowComps.hour   = time.hour
            tomorrowComps.minute = time.minute

            let content = UNMutableNotificationContent()
            content.title = "Drinky Poo"
            content.body  = "Don't forget to log today!"
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: repeatingID,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: tomorrowComps, repeats: true)
            )
            UNUserNotificationCenter.current().add(request)
        }
    }

    /// Re-adds today's reminder if the user un-logs a day and reminder time hasn't passed.
    func restoreTodayNotificationIfNeeded(reminderTime: DateComponents?) {
        guard let time = reminderTime else { return }

        let cal = Calendar.current
        let now = Date()
        var comps = DateComponents()
        comps.year   = cal.component(.year,  from: now)
        comps.month  = cal.component(.month, from: now)
        comps.day    = cal.component(.day,   from: now)
        comps.hour   = time.hour
        comps.minute = time.minute

        guard let fireDate = cal.date(from: comps), fireDate > now else { return }
        scheduleDailyReminder(at: time)
    }
}
