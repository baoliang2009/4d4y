import Foundation

struct ForumUser: Codable {
    let uid: Int
    let username: String
    let avatar: String?
    let isOnline: Bool
    let gender: String?
    let qq: String?
    let msn: String?
    let userGroup: String
    let registrationDate: String?
    let lastVisitDate: String?
    let lastPostDate: String?
    let registrationIP: String?
    let lastVisitIP: String?
    let postLevel: String?
    let readPermission: Int
    let totalPosts: Int
    let dailyAveragePosts: Double
    let essencePosts: Int
    let pageViews: Int
    let totalOnlineHours: Double
    let monthOnlineHours: Double
    let credits: Int
    let prestige: Int
    let money: Int
    let sellerCredit: Int
    let buyerCredit: Int

    init(uid: Int, username: String, avatar: String?, isOnline: Bool = false, gender: String? = nil, qq: String? = nil, msn: String? = nil, userGroup: String = "", registrationDate: String? = nil, lastVisitDate: String? = nil, lastPostDate: String? = nil, registrationIP: String? = nil, lastVisitIP: String? = nil, postLevel: String? = nil, readPermission: Int = 0, totalPosts: Int = 0, dailyAveragePosts: Double = 0, essencePosts: Int = 0, pageViews: Int = 0, totalOnlineHours: Double = 0, monthOnlineHours: Double = 0, credits: Int = 0, prestige: Int = 0, money: Int = 0, sellerCredit: Int = 0, buyerCredit: Int = 0) {
        self.uid = uid
        self.username = username
        self.avatar = avatar
        self.isOnline = isOnline
        self.gender = gender
        self.qq = qq
        self.msn = msn
        self.userGroup = userGroup
        self.registrationDate = registrationDate
        self.lastVisitDate = lastVisitDate
        self.lastPostDate = lastPostDate
        self.registrationIP = registrationIP
        self.lastVisitIP = lastVisitIP
        self.postLevel = postLevel
        self.readPermission = readPermission
        self.totalPosts = totalPosts
        self.dailyAveragePosts = dailyAveragePosts
        self.essencePosts = essencePosts
        self.pageViews = pageViews
        self.totalOnlineHours = totalOnlineHours
        self.monthOnlineHours = monthOnlineHours
        self.credits = credits
        self.prestige = prestige
        self.money = money
        self.sellerCredit = sellerCredit
        self.buyerCredit = buyerCredit
    }

    static var current: ForumUser? {
        let uid = LoginManager.shared.uid
        guard let username = LoginManager.shared.username, uid > 0 else {
            return nil
        }
        return ForumUser(
            uid: uid,
            username: username,
            avatar: nil
        )
    }
}
