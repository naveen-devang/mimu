import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Requests local notification permissions.
    func requestAuthorization(completion: @escaping (Bool) -> Void = { _ in }) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("NotificationManager: Permission request error: \(error.localizedDescription)")
            } else {
                print("NotificationManager: Permissions granted? \(granted)")
            }
            completion(granted)
        }
    }
    
    /// Checks the current authorization status.
    func getAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }
    
    /// Schedules a local notification for an AppEvent.
    func scheduleNotification(for event: AppEvent) {
        // Only schedule notifications for events in the future.
        guard event.date > Date() else {
            print("NotificationManager: Cannot schedule notification in the past for: \(event.title)")
            return
        }
        
        // Ensure permissions are granted before scheduling.
        getAuthorizationStatus { [weak self] status in
            guard let self else { return }
            
            switch status {
            case .authorized, .provisional:
                self.performScheduling(for: event)
            case .notDetermined:
                self.requestAuthorization { granted in
                    if granted {
                        self.performScheduling(for: event)
                    }
                }
            case .denied:
                print("NotificationManager: Cannot schedule notification because permissions are denied by user.")
            @unknown default:
                break
            }
        }
    }
    
    /// Internal helper to construct and register the UNNotificationRequest.
    private func performScheduling(for event: AppEvent) {
        let content = UNMutableNotificationContent()
        content.title = "Cozy Reminder! ⏰"
        content.body = event.title
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: event.date)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("NotificationManager: Failed to schedule notification for \(event.id.uuidString): \(error.localizedDescription)")
            } else {
                print("NotificationManager: Scheduled notification for \(event.title) at \(event.date)")
            }
        }
    }
    
    /// Cancels a pending notification for an AppEvent.
    func cancelNotification(for event: AppEvent) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [event.id.uuidString])
        print("NotificationManager: Cancelled scheduled notification for: \(event.title) (\(event.id.uuidString))")
    }
}
