import SwiftUI
import UIKit
import UserNotifications

class NotificationManager: ObservableObject {
    @Published var isNotificationEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(isNotificationEnabled, forKey: "notificationsEnabled")
            if !isNotificationEnabled {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
        }
    }

    @Published var notificationTime: Date = Date() {
        didSet {
            UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
            if isNotificationEnabled {
                scheduleNotification()
            }
        }
    }

    @Published var hasPermission: Bool = false

    init() {
        isNotificationEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        if let savedTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
            notificationTime = savedTime
        } else {
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            notificationTime = Calendar.current.date(from: components) ?? Date()
        }
        checkNotificationPermission()
    }

    func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.hasPermission = settings.authorizationStatus == .authorized
            }
        }
    }

    func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.hasPermission = granted
                completion(granted)
            }
        }
    }

    func scheduleNotification() {
        guard isNotificationEnabled && hasPermission else { return }
        guard WisdomManager.shared.isLoaded else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.scheduleNotification()
            }
            return
        }

        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: notificationTime)
        let quotes = WisdomManager.shared.quotes
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else { continue }
            let dateString = formatter.string(from: targetDate)
            let index = dateString.unicodeScalars.map { Int($0.value) }.reduce(0, +) % quotes.count
            let quote = quotes[index]

            let content = UNMutableNotificationContent()
            content.title = "Daily Wisdom"
            content.body = quote.text
            if let author = quote.author { content.subtitle = author }
            content.sound = .default

            var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: targetDate)
            dateComponents.hour = timeComponents.hour
            dateComponents.minute = timeComponents.minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: "dailyWisdom-\(dateString)", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        }
    }
}
