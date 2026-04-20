import Foundation

struct ForumPost: Codable {
    let pid: Int
    let author: String
    let authorUid: Int
    let authorAvatar: String?
    let postDate: String
    let content: String
    let images: [String]
    let floorNumber: Int
    let title: String?
    let viewCount: Int

    init(pid: Int, author: String, authorUid: Int, authorAvatar: String?, postDate: String, content: String, images: [String], floorNumber: Int, title: String? = nil, viewCount: Int = 0) {
        self.pid = pid
        self.author = author
        self.authorUid = authorUid
        self.authorAvatar = authorAvatar
        self.postDate = postDate
        self.content = content
        self.images = images
        self.floorNumber = floorNumber
        self.title = title
        self.viewCount = viewCount
    }
}
