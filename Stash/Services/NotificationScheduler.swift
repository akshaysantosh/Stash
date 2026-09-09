import Foundation
import UserNotifications

/// Schedules the single daily "recall" notification — a generic teaser only. The actual random
/// item is picked fresh in-app (DailyRecallView) when the notification is tapped, not baked into
/// the notification content, so it's never stale even if the app hasn't been opened in a while.
enum NotificationScheduler {
    static let identifier = "com.akshay.stash.dailyRecall"
    static let tagUserInfoKey = "tag"

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
    }

    static func schedule(tag: String, hour: Int, minute: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to revisit your \(tag) stash"
        content.body = "Tap to see what you saved."
        content.sound = .default
        content.userInfo = [tagUserInfoKey: tag]

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }
}
