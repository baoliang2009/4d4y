import Foundation

struct PrivateMessage: Identifiable {
    let id: Int
    let pmid: Int
    let fromUid: Int
    let fromUsername: String
    let fromAvatar: String?
    let toUid: Int
    let subject: String
    let summary: String
    let messageDate: String
    let isNew: Bool
    let folder: PMFolder

    enum PMFolder {
        case inbox
        case outbox
    }
}
