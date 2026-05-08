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

    func checkPMs(for accountId: UUID) async -> [NotificationItem] {
        guard let lastCheck = AccountManager.shared.getLastCheckTimestamp(for: accountId) else {
            return [] // First check, don't notify for existing messages
        }

        do {
            let urlString = "https://www.4d4y.com/forum/pm.php?folder=inbox"
            guard let url = URL(string: urlString) else { return [] }

            let (data, _) = try await URLSession.shared.data(from: url)
            let messages = try ForumHTMLParser.parsePrivateMessages(data)

            var items: [NotificationItem] = []
            for pm in messages {
                // Parse PM date to compare with lastCheck
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm"
                guard let pmDate = formatter.date(from: pm.messageDate) else { continue }

                if pmDate > lastCheck {
                    let item = NotificationItem(
                        id: "pm_\(pm.pmid)",
                        type: .pm,
                        threadId: nil,
                        postId: pm.pmid,
                        title: pm.subject,
                        preview: pm.summary,
                        date: pmDate,
                        accountId: accountId
                    )
                    items.append(item)
                }
            }
            return items
        } catch {
            print("[NotificationChecker] Failed to check PMs: \(error)")
            return []
        }
    }

    func checkReplies(for accountId: UUID) async -> [NotificationItem] {
        guard let account = AccountManager.shared.accounts.first(where: { $0.id == accountId }),
              account.uid > 0 else {
            return [] // Need valid UID for checking replies
        }

        guard let lastCheck = AccountManager.shared.getLastCheckTimestamp(for: accountId) else {
            return []
        }

        do {
            let urlString = "https://www.4d4y.com/forum/space.php?uid=\(account.uid)&do=posts"
            guard let url = URL(string: urlString) else { return [] }

            let (data, _) = try await URLSession.shared.data(from: url)
            // Parse user's recent posts - the HTML parser may need to be extended
            // For now, return empty as the space.php page structure needs investigation
            // This is a placeholder that can be filled in when the actual page structure is known

            return []
        } catch {
            print("[NotificationChecker] Failed to check replies: \(error)")
            return []
        }
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
