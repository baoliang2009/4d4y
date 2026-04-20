import Foundation

struct SearchResult {
    let tid: Int
    let title: String
    let forumName: String
    let forumFid: Int
    let author: String
    let authorUid: Int
    let postDate: String
    let replyCount: Int
    let viewCount: Int
    let lastPostAuthor: String
    let lastPostDate: String
}

struct SearchDetail {
    let keyword: String
    let totalResults: Int
    let currentPage: Int
    let totalPages: Int
    let results: [SearchResult]
}
