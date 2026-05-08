import Foundation

struct Account: Codable, Identifiable {
    let id: UUID
    var username: String
    var uid: Int
    var createdAt: Date
    var lastUsedAt: Date
    var isCurrent: Bool

    init(id: UUID = UUID(), username: String, uid: Int = 0, createdAt: Date = Date(), lastUsedAt: Date = Date(), isCurrent: Bool = false) {
        self.id = id
        self.username = username
        self.uid = uid
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.isCurrent = isCurrent
    }
}

struct AccountCredentials {
    let accountId: UUID
    let username: String
    let password: String
    let questionId: Int
    let answer: String
}

struct AccountCookies: Codable {
    let accountId: UUID
    let cookiesData: Data
}

enum NotificationType: String, Codable {
    case reply
    case pm
}

struct NotificationItem: Codable, Identifiable {
    let id: String
    let type: NotificationType
    let threadId: Int?
    let postId: Int?
    let title: String
    let preview: String
    let date: Date
    let accountId: UUID
    var isRead: Bool

    init(id: String, type: NotificationType, threadId: Int?, postId: Int?, title: String, preview: String, date: Date, accountId: UUID, isRead: Bool = false) {
        self.id = id
        self.type = type
        self.threadId = threadId
        self.postId = postId
        self.title = title
        self.preview = preview
        self.date = date
        self.accountId = accountId
        self.isRead = isRead
    }
}
