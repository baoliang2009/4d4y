import Foundation

struct Forum: Codable {
    let fid: Int
    let name: String
    let description: String
    let threadCount: Int
    let postCount: Int
    
    var displayName: String {
        if name.count > 15 {
            return String(name.prefix(15)) + "..."
        }
        return name
    }
}

class ForumManager {
    static let shared = ForumManager()
    
    private let favoriteForumsKey = "forum_favorite_forums_data"
    private let lastVisitedFidKey = "forum_last_visited_fid"
    
    private let allForumsList: [Forum] = [
        Forum(fid: 56, name: "iPhone, iPod Touch & iPad", description: "苹果产品相关讨论", threadCount: 7222, postCount: 106196),
        Forum(fid: 9, name: "Smartphone", description: "智能手机综合讨论", threadCount: 32764, postCount: 400132),
        Forum(fid: 7, name: "Geek Talks 圈 物与聚聊", description: "数码产品、蓝牙、WiFi、嵌入式Linux等", threadCount: 40461, postCount: 551787),
        Forum(fid: 60, name: "Android, Chrome & Google", description: "Android和Google产品", threadCount: 958, postCount: 8096),
        Forum(fid: 22, name: "苹果帝国", description: "苹果生态系统讨论", threadCount: 2544, postCount: 16764),
        Forum(fid: 12, name: "PalmOS 与Treo", description: "PalmOS和相关硬件", threadCount: 82598, postCount: 743855),
        Forum(fid: 14, name: "Windows Mobile与PocketPC", description: "Windows Mobile设备", threadCount: 68909, postCount: 454000),
        Forum(fid: 50, name: "DC,NB,MP3,Gadgets", description: "数码相机、笔记本、MP3等", threadCount: 21795, postCount: 184104)
    ]
    
    private let defaultFavoriteFids: [Int] = [56, 9, 7, 60, 22]
    
    private init() {
        if favoriteFids.isEmpty {
            favoriteFids = defaultFavoriteFids
        }
    }
    
    var favoriteFids: [Int] {
        get {
            let fids = UserDefaults.standard.array(forKey: favoriteForumsKey) as? [Int]
            return fids ?? defaultFavoriteFids
        }
        set {
            UserDefaults.standard.set(newValue, forKey: favoriteForumsKey)
        }
    }
    
    var lastVisitedFid: Int {
        get { UserDefaults.standard.integer(forKey: lastVisitedFidKey) }
        set { UserDefaults.standard.set(newValue, forKey: lastVisitedFidKey) }
    }
    
    var favoriteForums: [Forum] {
        let fids = favoriteFids
        return allForumsList.filter { fids.contains($0.fid) }
            .sorted { fids.firstIndex(of: $0.fid)! < fids.firstIndex(of: $1.fid)! }
    }
    
    var allForums: [Forum] {
        return allForumsList
    }
    
    func urlForForum(fid: Int) -> URL {
        if fid == 0 {
            return URL(string: "https://www.4d4y.com/forum/")!
        }
        return URL(string: "https://www.4d4y.com/forum/forumdisplay.php?fid=\(fid)")!
    }
    
    func forumById(_ fid: Int) -> Forum? {
        return allForumsList.first { $0.fid == fid }
    }
    
    func isFavorite(_ fid: Int) -> Bool {
        return favoriteFids.contains(fid)
    }
    
    func addToFavorites(_ fid: Int) {
        var fids = favoriteFids
        if !fids.contains(fid) {
            fids.append(fid)
            favoriteFids = fids
        }
    }
    
    func removeFromFavorites(_ fid: Int) {
        var fids = favoriteFids
        fids.removeAll { $0 == fid }
        favoriteFids = fids
    }
    
    func toggleFavorite(_ fid: Int) {
        if isFavorite(fid) {
            removeFromFavorites(fid)
        } else {
            addToFavorites(fid)
        }
    }
    
    func updateLastVisited(fid: Int) {
        lastVisitedFid = fid
    }
    
    func getLastVisitedForum() -> Forum? {
        if lastVisitedFid == 0 {
            return nil
        }
        return forumById(lastVisitedFid)
    }
    
    func getLastVisitedURL() -> URL {
        if lastVisitedFid > 0 {
            return urlForForum(fid: lastVisitedFid)
        }
        return URL(string: "https://www.4d4y.com/forum/")!
    }
    
    func getForumDisplayName(_ fid: Int) -> String {
        if fid == 0 {
            return "论坛首页"
        }
        if let forum = forumById(fid) {
            return forum.displayName
        }
        return "版块"
    }

    // MARK: - Forum Typeid Options (分类)

    /// 分类选项结构
    struct TypeidOption {
        let id: Int
        let name: String
    }

    /// 根据 fid 获取分类选项
    func getTypeidOptions(for fid: Int) -> [TypeidOption] {
        // 已知的分类选项
        let typeidOptions: [Int: [TypeidOption]] = [
            // fid=2 Discovery
            2: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 9, name: "聚会"),
                TypeidOption(id: 33, name: "汽车"),
                TypeidOption(id: 38, name: "大杂烩"),
                TypeidOption(id: 40, name: "助学"),
                TypeidOption(id: 56, name: "Discovery"),
                TypeidOption(id: 57, name: "投资"),
                TypeidOption(id: 58, name: "职场"),
                TypeidOption(id: 65, name: "文艺"),
                TypeidOption(id: 66, name: "版喃"),
                TypeidOption(id: 67, name: "显摆"),
                TypeidOption(id: 79, name: "晒物劝败"),
                TypeidOption(id: 81, name: "装修"),
                TypeidOption(id: 82, name: "推片"),
                TypeidOption(id: 39, name: "YY"),
                TypeidOption(id: 19, name: "站务")
            ],
            // fid=6 数码产品 (根据用户提供的HTML)
            6: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 1, name: "手机"),
                TypeidOption(id: 2, name: "掌上电脑"),
                TypeidOption(id: 3, name: "笔记本电脑"),
                TypeidOption(id: 4, name: "无线产品"),
                TypeidOption(id: 5, name: "数码相机、摄像机"),
                TypeidOption(id: 6, name: "MP3随身听"),
                TypeidOption(id: 7, name: "各类配件"),
                TypeidOption(id: 8, name: "其他好玩的"),
                TypeidOption(id: 19, name: "站务")
            ],
            // fid=7 Geek Talks
            7: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 20, name: "Gadgets"),
                TypeidOption(id: 21, name: "无线"),
                TypeidOption(id: 22, name: "嵌入式Linux"),
                TypeidOption(id: 41, name: "业界"),
                TypeidOption(id: 74, name: "安卓"),
                TypeidOption(id: 76, name: "高清播放器"),
                TypeidOption(id: 19, name: "站务")
            ],
            // fid=9 Smartphone
            9: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 23, name: "Symbian"),
                TypeidOption(id: 24, name: "PalmOS"),
                TypeidOption(id: 25, name: "Linux"),
                TypeidOption(id: 26, name: "Windows Mobile"),
                TypeidOption(id: 27, name: "运营商"),
                TypeidOption(id: 28, name: "Other"),
                TypeidOption(id: 59, name: "BlackBerry"),
                TypeidOption(id: 19, name: "站务")
            ],
            // fid=12 PalmOS
            12: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 43, name: "Treo"),
                TypeidOption(id: 45, name: "Palm硬件"),
                TypeidOption(id: 46, name: "Clie"),
                TypeidOption(id: 47, name: "各类软件"),
                TypeidOption(id: 48, name: "汉化"),
                TypeidOption(id: 63, name: "Pre"),
                TypeidOption(id: 64, name: "WebOS"),
                TypeidOption(id: 78, name: "pixi"),
                TypeidOption(id: 18, name: "求助"),
                TypeidOption(id: 19, name: "站务")
            ],
            // fid=14 Windows Mobile
            14: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 19, name: "站务")
            ],
            // fid=22 苹果帝国
            22: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 19, name: "站务")
            ],
            // fid=50 DC,NB,MP3,Gadgets
            50: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 19, name: "站务")
            ],
            // fid=56 iPhone, iPad
            56: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 19, name: "站务")
            ],
            // fid=60 Android
            60: [
                TypeidOption(id: 0, name: "分类"),
                TypeidOption(id: 19, name: "站务")
            ]
        ]

        // 返回已知板块的分类，或者返回默认分类
        if let options = typeidOptions[fid] {
            return options
        }

        // 默认分类（未知板块）
        return [
            TypeidOption(id: 0, name: "分类"),
            TypeidOption(id: 19, name: "站务")
        ]
    }
}
