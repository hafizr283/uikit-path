// Worked solution: Schedule and cancel a local reminder
// Authorization can take time, so the solution recomputes the remaining interval afterward. A scheduled request is not a promise of exact visual delivery: user settings and system behavior still apply. Foreground presentation and tap routing require a UNUserNotificationCenterDelegate wired by the app.
// Read lessons/day-19.md for any surrounding types or setup.

import Foundation
import UserNotifications

enum ReminderError: Error {
    case denied
    case invalidDate
}

@MainActor
struct ReminderScheduler {
    private func identifier(for id: UUID) -> String {
        "task-reminder-" + id.uuidString
    }

    func schedule(taskID: UUID, at date: Date) async throws {
        let interval = date.timeIntervalSinceNow
        guard interval >= 1 else {
            throw ReminderError.invalidDate
        }
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(
            options: [.alert, .sound]
        )
        guard granted else { throw ReminderError.denied }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "Task reminder")
        content.body = String(localized: "Open PocketTasks to review your task.")
        content.sound = .default
        content.userInfo = ["taskID": taskID.uuidString]

        let remaining = date.timeIntervalSinceNow
        guard remaining >= 1 else {
            throw ReminderError.invalidDate
        }
        let request = UNNotificationRequest(
            identifier: identifier(for: taskID),
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: remaining, repeats: false
            )
        )
        try await center.add(request)
    }

    func cancel(taskID: UUID) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: [identifier(for: taskID)]
            )
    }
}
