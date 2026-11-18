import Foundation
import UserNotifications

// Handles local notifications (permission, sending, cancelling)
class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    // Ask the user for permission once
    func requestPermission() {
        center.delegate = self
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    // Show notifications even while the app is open
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // Send now (date = nil) or schedule for a specific date
    func send(title: String, body: String, id: String = UUID().uuidString, at date: Date? = nil) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var trigger: UNNotificationTrigger?
        if let date {
            let seconds = date.timeIntervalSinceNow
            guard seconds > 0 else { return } // Skip dates in the past
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        }

        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    func cancel(ids: [String]) {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }
}
