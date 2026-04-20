import Foundation

struct ThreadDetail: Codable {
    let title: String
    let posts: [ForumPost]
    let totalPages: Int
    let currentPage: Int
}

struct LoginFormData {
    let formhash: String
    let questionId: Int
}
