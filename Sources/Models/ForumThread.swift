import Foundation

struct ForumThread: Codable {
    let tid: Int
    let title: String
    let author: String
    let authorUid: Int
    let replyCount: Int
    let viewCount: Int
    let lastPostDate: String
    let lastPostAuthor: String

    var displayTitle: String {
        if title.count > 50 {
            return String(title.prefix(50)) + "..."
        }
        return title
    }
}
