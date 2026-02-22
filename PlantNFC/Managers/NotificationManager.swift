import Foundation
import UserNotifications
import CoreData

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    // MARK: - Permission
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, _ in
            DispatchQueue.main.async {
                self.isAuthorized = granted
            }
        }
    }

    // MARK: - Schedule notification for plant
    func scheduleNotification(for plant: PlantEntity) {
        guard let next = plant.nextWaterDate,
              let id = plant.id else { return }

        let identifier = notificationID(for: plant)
        cancelNotifications(for: plant)

        // First notification at the exact next water date
        scheduleOneNotification(
            identifier: identifier + "-0",
            title: "\(plant.wrappedEmoji) \(plant.wrappedName) heeft water nodig!",
            body: "Het is tijd om \(plant.wrappedName) water te geven. Scan de NFC-tag om te bevestigen. 💧",
            date: next,
            plantID: id
        )

        // Follow-up reminders every 4 hours if not scanned
        for i in 1...6 {
            let reminderDate = next.addingTimeInterval(Double(i) * 4 * 3600)
            scheduleOneNotification(
                identifier: "\(identifier)-\(i)",
                title: "⏰ \(plant.wrappedName) wacht nog op water!",
                body: "Vergeet \(plant.wrappedName) niet! Scan de NFC-tag als je water hebt gegeven. 🌿",
                date: reminderDate,
                plantID: id
            )
        }
    }

    private func scheduleOneNotification(identifier: String, title: String, body: String, date: Date, plantID: UUID) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = NSNumber(value: 1)
        content.userInfo = ["plantID": plantID.uuidString]

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification schedule error: \(error)")
            }
        }
    }

    // MARK: - Cancel notifications for plant
    func cancelNotifications(for plant: PlantEntity) {
        let base = notificationID(for: plant)
        var identifiers = [base + "-0"]
        for i in 1...6 { identifiers.append("\(base)-\(i)") }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    // MARK: - Reschedule all plants (called from background task)
    func rescheduleAll() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<PlantEntity> = PlantEntity.fetchRequest()

        guard let plants = try? context.fetch(request) else { return }
        for plant in plants {
            scheduleNotification(for: plant)
        }
    }

    // MARK: - Clear badge
    func clearBadge() {
        UNUserNotificationCenter.current()
            .setBadgeCount(0, withCompletionHandler: nil)
    }

    // MARK: - Helper
    private func notificationID(for plant: PlantEntity) -> String {
        "plantnfc-\(plant.id?.uuidString ?? "unknown")"
    }
}
