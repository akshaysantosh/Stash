import UserNotifications

/// Bridges a tapped notification into an in-app sheet. Also shows the banner while the app is
/// foregrounded (iOS suppresses it by default), which is handy for testing the daily recall
/// without backgrounding the app first.
@MainActor
final class NotificationRouter: NSObject, ObservableObject {
    @Published var pendingRecallTag: String?
}

extension NotificationRouter: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let tag = response.notification.request.content.userInfo[NotificationScheduler.tagUserInfoKey] as? String
        Task { @MainActor in
            self.pendingRecallTag = tag
        }
        completionHandler()
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
