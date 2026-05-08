import Foundation
import UserNotifications

class NotificationChecker {
    static let shared = NotificationChecker()

    private init() {}

    func checkAllAccounts() async {
        let accounts = AccountManager.shared.accounts

        for account in accounts {
            AccountManager.shared.loadCookies(for: account.id)
            let newReplies = await checkReplies(for: account.id)
            let newPMs = await checkPMs(for: account.id)

            for item in newReplies + newPMs {
                await scheduleNotification(for: item)
            }

            AccountManager.shared.saveLastCheckTimestamp(for: account.id, date: Date())
        }
    }

    func checkReplies(for accountId: UUID) async -> [NotificationItem] {
        return []
    }

    func checkPMs(for accountId: UUID) async -> [NotificationItem] {
        return []
    }

    private func scheduleNotification(for item: NotificationItem) async {
        let content = UNMutableNotificationContent()

        switch item.type {
        case .reply:
            content.title = "新回复"
            content.body = item.title
            content.sound = .default
            content.categoryIdentifier = "REPLY"
            content.userInfo = [
                "threadId": item.threadId ?? 0,
                "postId": item.postId ?? 0
            ]
        case .pm:
            content.title = "新私信"
            content.body = item.title
            content.sound = .default
            content.categoryIdentifier = "PM"
            content.userInfo = [
                "pmId": item.id
            ]
        }

        let request = UNNotificationRequest(
            identifier: item.id,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("[NotificationChecker] Failed to schedule notification: \(error)")
        }
    }
}