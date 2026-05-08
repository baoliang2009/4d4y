import Foundation
import BackgroundTasks
import UserNotifications

class BackgroundTaskService {
    static let shared = BackgroundTaskService()

    private let backgroundTaskIdentifier = "com.fourd4y.hipda.refresh"

    private init() {}

    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleBackgroundFetch() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BackgroundTask] Scheduled background fetch")
        } catch {
            print("[BackgroundTask] Failed to schedule: \(error)")
        }
    }

    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleBackgroundFetch()

        let checkTask = Task {
            await NotificationChecker.shared.checkAllAccounts()
        }

        task.expirationHandler = {
            checkTask.cancel()
        }

        Task {
            await checkTask.value
            task.setTaskCompleted(success: true)
        }
    }

    func registerNotificationCategories() {
        let viewReplyAction = UNNotificationAction(identifier: "VIEW_REPLY", title: "查看", options: .foreground)
        let replyAction = UNNotificationAction(identifier: "REPLY", title: "回复", options: .foreground)
        let replyCategory = UNNotificationCategory(
            identifier: "REPLY",
            actions: [viewReplyAction, replyAction],
            intentIdentifiers: [],
            options: []
        )

        let viewPMAction = UNNotificationAction(identifier: "VIEW_PM", title: "查看", options: .foreground)
        let pmCategory = UNNotificationCategory(
            identifier: "PM",
            actions: [viewPMAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([replyCategory, pmCategory])
    }
}