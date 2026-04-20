import Foundation

struct PMDetail {
    let fromUid: Int
    let fromUsername: String
    let messages: [PMMessage]
    let currentPage: Int
    let totalPages: Int
    let formhash: String?
}

struct PMMessage: Identifiable {
    let id: Int
    let pmid: Int
    let author: String
    let authorUid: Int
    let authorAvatar: String?
    let postDate: String
    let content: String
    let isSelf: Bool
}
