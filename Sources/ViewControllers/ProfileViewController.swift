import UIKit
import WebKit

class ProfileViewController: UIViewController, LoginViewControllerDelegate {

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let avatarImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let uidLabel = UILabel()
    private let onlineStatusView = UIView()
    private let onlineStatusLabel = UILabel()

    private let statsContainer = UIView()
    private let threadsCountLabel = UILabel()
    private let postsCountLabel = UILabel()
    private let creditsCountLabel = UILabel()

    private let infoCard = UIView()
    private let infoStackView = UIStackView()
    private let loginButton = UIButton(type: .system)
    private let logoutButton = UIButton(type: .system)

    private let menuStackView = UIStackView()

    private var userProfile: ForumUser?
    private var isLoading = false
    private var currentFetchingUid: Int = 0

    // Hidden WKWebView for fetching profile
    private var profileWebView: WKWebView?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("[Profile] viewWillAppear called")
        loadUserData()
    }

    private func setupUI() {
        title = "我的"
        view.backgroundColor = Theme.background

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        setupProfileHeader()
        setupStatsSection()
        setupInfoCard()
        setupMenuSection()
        setupActionButtons()

        // Initialize with empty state
        updateUIForLoggedOut()
    }

    private func setupProfileHeader() {
        // Avatar
        avatarImageView.backgroundColor = Theme.muted
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 40
        avatarImageView.clipsToBounds = true
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = Theme.secondaryText
        contentView.addSubview(avatarImageView)

        // Username
        usernameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        usernameLabel.textColor = Theme.titleText
        usernameLabel.textAlignment = .center
        usernameLabel.text = "未登录"
        contentView.addSubview(usernameLabel)

        // UID
        uidLabel.font = .systemFont(ofSize: 14)
        uidLabel.textColor = Theme.secondaryText
        uidLabel.textAlignment = .center
        uidLabel.text = ""
        contentView.addSubview(uidLabel)

        // Online status
        onlineStatusView.backgroundColor = Theme.muted
        onlineStatusView.layer.cornerRadius = 4
        contentView.addSubview(onlineStatusView)

        onlineStatusLabel.font = .systemFont(ofSize: 12)
        onlineStatusLabel.textColor = .white
        onlineStatusLabel.textAlignment = .center
        onlineStatusLabel.text = "离线"
        contentView.addSubview(onlineStatusLabel)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        uidLabel.translatesAutoresizingMaskIntoConstraints = false
        onlineStatusView.translatesAutoresizingMaskIntoConstraints = false
        onlineStatusLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 80),
            avatarImageView.heightAnchor.constraint(equalToConstant: 80),

            usernameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 12),
            usernameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            uidLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            uidLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            onlineStatusView.topAnchor.constraint(equalTo: uidLabel.bottomAnchor, constant: 8),
            onlineStatusView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            onlineStatusView.heightAnchor.constraint(equalToConstant: 20),

            onlineStatusLabel.topAnchor.constraint(equalTo: onlineStatusView.topAnchor),
            onlineStatusLabel.bottomAnchor.constraint(equalTo: onlineStatusView.bottomAnchor),
            onlineStatusLabel.leadingAnchor.constraint(equalTo: onlineStatusView.leadingAnchor, constant: 12),
            onlineStatusLabel.trailingAnchor.constraint(equalTo: onlineStatusView.trailingAnchor, constant: -12)
        ])
    }

    private func setupStatsSection() {
        statsContainer.backgroundColor = Theme.card
        statsContainer.layer.cornerRadius = 12
        statsContainer.layer.borderColor = Theme.border.cgColor
        statsContainer.layer.borderWidth = 1
        contentView.addSubview(statsContainer)

        let threadsTitleLabel = UILabel()
        threadsTitleLabel.text = "主题"
        threadsTitleLabel.font = .systemFont(ofSize: 12)
        threadsTitleLabel.textColor = Theme.secondaryText
        threadsTitleLabel.textAlignment = .center

        threadsCountLabel.text = "0"
        threadsCountLabel.font = .systemFont(ofSize: 20, weight: .bold)
        threadsCountLabel.textColor = Theme.primary
        threadsCountLabel.textAlignment = .center

        let postsTitleLabel = UILabel()
        postsTitleLabel.text = "回复"
        postsTitleLabel.font = .systemFont(ofSize: 12)
        postsTitleLabel.textColor = Theme.secondaryText
        postsTitleLabel.textAlignment = .center

        postsCountLabel.text = "0"
        postsCountLabel.font = .systemFont(ofSize: 20, weight: .bold)
        postsCountLabel.textColor = Theme.primary
        postsCountLabel.textAlignment = .center

        let creditsTitleLabel = UILabel()
        creditsTitleLabel.text = "积分"
        creditsTitleLabel.font = .systemFont(ofSize: 12)
        creditsTitleLabel.textColor = Theme.secondaryText
        creditsTitleLabel.textAlignment = .center

        creditsCountLabel.text = "0"
        creditsCountLabel.font = .systemFont(ofSize: 20, weight: .bold)
        creditsCountLabel.textColor = Theme.primary
        creditsCountLabel.textAlignment = .center

        let threadsStack = UIStackView(arrangedSubviews: [threadsCountLabel, threadsTitleLabel])
        threadsStack.axis = .vertical
        threadsStack.spacing = 4
        threadsStack.alignment = .center

        let postsStack = UIStackView(arrangedSubviews: [postsCountLabel, postsTitleLabel])
        postsStack.axis = .vertical
        postsStack.spacing = 4
        postsStack.alignment = .center

        let creditsStack = UIStackView(arrangedSubviews: [creditsCountLabel, creditsTitleLabel])
        creditsStack.axis = .vertical
        creditsStack.spacing = 4
        creditsStack.alignment = .center

        let divider1 = UIView()
        divider1.backgroundColor = Theme.border

        let divider2 = UIView()
        divider2.backgroundColor = Theme.border

        statsContainer.addSubview(threadsStack)
        statsContainer.addSubview(divider1)
        statsContainer.addSubview(postsStack)
        statsContainer.addSubview(divider2)
        statsContainer.addSubview(creditsStack)

        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        threadsStack.translatesAutoresizingMaskIntoConstraints = false
        divider1.translatesAutoresizingMaskIntoConstraints = false
        postsStack.translatesAutoresizingMaskIntoConstraints = false
        divider2.translatesAutoresizingMaskIntoConstraints = false
        creditsStack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statsContainer.topAnchor.constraint(equalTo: onlineStatusView.bottomAnchor, constant: 20),
            statsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statsContainer.heightAnchor.constraint(equalToConstant: 80),

            threadsStack.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 20),
            threadsStack.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),

            divider1.centerXAnchor.constraint(equalTo: statsContainer.centerXAnchor, constant: -60),
            divider1.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),
            divider1.widthAnchor.constraint(equalToConstant: 1),
            divider1.heightAnchor.constraint(equalToConstant: 40),

            postsStack.centerXAnchor.constraint(equalTo: statsContainer.centerXAnchor),
            postsStack.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),

            divider2.centerXAnchor.constraint(equalTo: statsContainer.centerXAnchor, constant: 60),
            divider2.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),
            divider2.widthAnchor.constraint(equalToConstant: 1),
            divider2.heightAnchor.constraint(equalToConstant: 40),

            creditsStack.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -20),
            creditsStack.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor)
        ])
    }

    private func setupInfoCard() {
        infoCard.backgroundColor = Theme.card
        infoCard.layer.cornerRadius = 12
        infoCard.layer.borderColor = Theme.border.cgColor
        infoCard.layer.borderWidth = 1
        contentView.addSubview(infoCard)

        infoStackView.axis = .vertical
        infoStackView.spacing = 8
        infoCard.addSubview(infoStackView)

        infoCard.translatesAutoresizingMaskIntoConstraints = false
        infoStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            infoCard.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 16),
            infoCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            infoCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            infoStackView.topAnchor.constraint(equalTo: infoCard.topAnchor, constant: 16),
            infoStackView.leadingAnchor.constraint(equalTo: infoCard.leadingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: infoCard.trailingAnchor, constant: -16),
            infoStackView.bottomAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: -16)
        ])
    }

    private func updateInfoCard(with profile: ForumUser) {
        infoStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if !profile.userGroup.isEmpty {
            infoStackView.addArrangedSubview(createInfoRow(icon: "person.badge.shield.checkmark", title: "用户组", value: profile.userGroup))
        }

        if let gender = profile.gender {
            infoStackView.addArrangedSubview(createInfoRow(icon: "person.fill", title: "性别", value: gender))
        }

        if let qq = profile.qq, !qq.isEmpty {
            infoStackView.addArrangedSubview(createInfoRow(icon: "message.fill", title: "QQ", value: qq))
        }

        if let regDate = profile.registrationDate {
            infoStackView.addArrangedSubview(createInfoRow(icon: "calendar", title: "注册日期", value: regDate))
        }

        if let lastVisit = profile.lastVisitDate {
            infoStackView.addArrangedSubview(createInfoRow(icon: "clock", title: "上次访问", value: lastVisit))
        }

        if let lastPost = profile.lastPostDate {
            infoStackView.addArrangedSubview(createInfoRow(icon: "pencil", title: "最后发表", value: lastPost))
        }

        if let postLevel = profile.postLevel, !postLevel.isEmpty {
            infoStackView.addArrangedSubview(createInfoRow(icon: "text.bubble", title: "发帖级别", value: postLevel))
        }

        infoStackView.addArrangedSubview(createInfoRow(icon: "eye", title: "阅读权限", value: "\(profile.readPermission)"))
        infoStackView.addArrangedSubview(createInfoRow(icon: "doc.text", title: "帖子数", value: "\(profile.totalPosts) 篇"))
        infoStackView.addArrangedSubview(createInfoRow(icon: "chart.bar", title: "日均发帖", value: String(format: "%.2f 篇", profile.dailyAveragePosts)))
        infoStackView.addArrangedSubview(createInfoRow(icon: "star.fill", title: "精华", value: "\(profile.essencePosts) 篇"))
        infoStackView.addArrangedSubview(createInfoRow(icon: "eye.fill", title: "页面访问量", value: "\(profile.pageViews)"))
        infoStackView.addArrangedSubview(createInfoRow(icon: "clock.fill", title: "总计在线", value: String(format: "%.1f 小时", profile.totalOnlineHours)))
        infoStackView.addArrangedSubview(createInfoRow(icon: "clock.badge.checkmark", title: "本月在线", value: String(format: "%.1f 小时", profile.monthOnlineHours)))

        infoStackView.addArrangedSubview(createInfoRow(icon: "bitcoinsign.circle", title: "积分", value: "\(profile.credits)"))
        infoStackView.addArrangedSubview(createInfoRow(icon: "star.circle", title: "威望", value: "\(profile.prestige)"))
        infoStackView.addArrangedSubview(createInfoRow(icon: "dollarsign.circle", title: "金钱", value: "\(profile.money)"))

        if profile.sellerCredit > 0 || profile.buyerCredit > 0 {
            infoStackView.addArrangedSubview(createInfoRow(icon: "checkmark.seal", title: "卖家信用", value: "\(profile.sellerCredit)"))
            infoStackView.addArrangedSubview(createInfoRow(icon: "cart", title: "买家信用", value: "\(profile.buyerCredit)"))
        }

        if infoStackView.arrangedSubviews.isEmpty {
            let placeholder = UILabel()
            placeholder.text = "暂无详细信息"
            placeholder.font = .systemFont(ofSize: 14)
            placeholder.textColor = Theme.secondaryText
            placeholder.textAlignment = .center
            infoStackView.addArrangedSubview(placeholder)
        }
    }

    private func createInfoRow(icon: String, title: String, value: String) -> UIView {
        let container = UIView()

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = Theme.primary
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14)
        titleLabel.textColor = Theme.secondaryText
        container.addSubview(titleLabel)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14)
        valueLabel.textColor = Theme.titleText
        valueLabel.textAlignment = .right
        valueLabel.numberOfLines = 0
        container.addSubview(valueLabel)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        valueLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 28),

            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            titleLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 80),

            valueLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            valueLabel.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 8)
        ])

        return container
    }

    private func setupMenuSection() {
        menuStackView.axis = .vertical
        menuStackView.spacing = 1
        menuStackView.backgroundColor = Theme.border
        menuStackView.layer.cornerRadius = 12
        menuStackView.clipsToBounds = true
        contentView.addSubview(menuStackView)

        let menuItems = [
            ("bookmark", "我的收藏"),
            ("clock.arrow.circlepath", "浏览历史"),
            ("gear", "设置")
        ]

        for (icon, title) in menuItems {
            let menuItem = createMenuItem(icon: icon, title: title)
            menuStackView.addArrangedSubview(menuItem)
        }

        menuStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            menuStackView.topAnchor.constraint(equalTo: infoCard.bottomAnchor, constant: 24),
            menuStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            menuStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private func createMenuItem(icon: String, title: String) -> UIView {
        let container = UIView()
        container.backgroundColor = Theme.card

        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = Theme.primary
        iconView.contentMode = .scaleAspectFit
        container.addSubview(iconView)

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = Theme.titleText
        container.addSubview(titleLabel)

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = Theme.secondaryText
        arrow.contentMode = .scaleAspectFit
        container.addSubview(arrow)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        arrow.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 52),

            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            arrow.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            arrow.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            arrow.widthAnchor.constraint(equalToConstant: 16),
            arrow.heightAnchor.constraint(equalToConstant: 16)
        ])

        return container
    }

    private func setupActionButtons() {
        loginButton.setTitle("登录", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        loginButton.backgroundColor = Theme.primary
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)
        contentView.addSubview(loginButton)

        logoutButton.setTitle("退出登录", for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        logoutButton.setTitleColor(.systemRed, for: .normal)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        logoutButton.isHidden = true
        contentView.addSubview(logoutButton)

        loginButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: menuStackView.bottomAnchor, constant: 30),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),

            logoutButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            logoutButton.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoutButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -30)
        ])
    }

    private func updateUIForLoggedOut() {
        usernameLabel.text = "未登录"
        uidLabel.text = ""
        onlineStatusView.backgroundColor = Theme.muted
        onlineStatusLabel.text = "离线"
        postsCountLabel.text = "0"
        creditsCountLabel.text = "0"
        loginButton.setTitle("登录", for: .normal)
        loginButton.backgroundColor = Theme.primary
        loginButton.isEnabled = true
        logoutButton.isHidden = true
        avatarImageView.image = UIImage(systemName: "person.circle.fill")

        let placeholderProfile = ForumUser(
            uid: 0,
            username: "未登录",
            avatar: nil
        )
        updateInfoCard(with: placeholderProfile)
    }

    private func updateUIForLoggedIn(username: String, uid: Int) {
        usernameLabel.text = username
        uidLabel.text = "UID: \(uid)"
        onlineStatusView.backgroundColor = Theme.muted
        onlineStatusLabel.text = "加载中..."
        loginButton.setTitle("已登录", for: .normal)
        loginButton.backgroundColor = Theme.muted
        loginButton.isEnabled = false
        logoutButton.isHidden = false
    }

    private func loadUserData() {
        print("[Profile] loadUserData called")
        print("[Profile] isLoggedIn: \(LoginManager.shared.isLoggedIn)")
        print("[Profile] username: \(LoginManager.shared.username ?? "nil")")
        print("[Profile] uid: \(LoginManager.shared.uid)")
        print("[Profile] isLoading: \(isLoading)")

        // Clean up any existing WKWebView
        if profileWebView != nil {
            print("[Profile] Cleaning up existing WKWebView")
            profileWebView?.removeFromSuperview()
            profileWebView = nil
            isLoading = false
        }

        if LoginManager.shared.isLoggedIn {
            let username = LoginManager.shared.username ?? "用户"
            var uid = LoginManager.shared.uid

            updateUIForLoggedIn(username: username, uid: uid)

            // If UID is 0, try to fetch it from server first
            if uid == 0 {
                print("[Profile] UID is 0, fetching UID from server...")
                fetchUidAndProfile()
            } else {
                // Use WKWebView to fetch profile (bypasses Cloudflare)
                print("[Profile] Calling fetchProfileWithWKWebView for uid: \(uid)")
                fetchProfileWithWKWebView(uid: uid)
            }
        } else {
            print("[Profile] User not logged in, showing logged out UI")
            updateUIForLoggedOut()
        }
    }

    private func fetchUidAndProfile() {
        if isLoading { return }
        isLoading = true
        currentFetchingUid = 0

        print("[Profile] Creating WKWebView to fetch UID from memcp.php")

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36"
        webView.navigationDelegate = self
        webView.isHidden = true
        self.profileWebView = webView
        view.addSubview(webView)

        let urlString = "https://www.4d4y.com/forum/memcp.php"
        print("[Profile] Loading URL: \(urlString)")
        webView.load(URLRequest(url: URL(string: urlString)!))
    }

    private func fetchProfileWithWKWebView(uid: Int) {
        if isLoading { return }
        isLoading = true
        currentFetchingUid = uid

        print("[Profile] Creating WKWebView to fetch profile for uid: \(uid)")

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36"
        webView.navigationDelegate = self
        webView.isHidden = true
        self.profileWebView = webView
        view.addSubview(webView)

        let urlString = "https://www.4d4y.com/forum/space.php?uid=\(uid)"
        print("[Profile] Loading URL: \(urlString)")
        webView.load(URLRequest(url: URL(string: urlString)!))
    }

    private func parseProfileHTML(_ html: String, defaultUid: Int) -> ForumUser? {
        do {
            // Try to parse as GBK
            let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x80000631)))
            let gb2312 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x80000630)))

            var decodedHTML = html
            if let data = html.data(using: .utf8) {
                if let gbDecoded = String(data: data, encoding: gb18030) {
                    decodedHTML = gbDecoded
                } else if let gb2Decoded = String(data: data, encoding: gb2312) {
                    decodedHTML = gb2Decoded
                }
            }

            print("[Profile] Parsing HTML length: \(decodedHTML.count)")

            // Extract username from h1
            var username = "未知用户"
            if let h1Range = decodedHTML.range(of: "<h1>") {
                let afterH1 = String(decodedHTML[h1Range.upperBound...])
                if let endRange = afterH1.range(of: "</h1>") {
                    username = String(afterH1[..<endRange.lowerBound])
                    // Remove any HTML tags like <img>
                    username = username.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                    username = username.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            // Extract UID from discuz_uid
            var extractedUid = 0
            if let uidRange = decodedHTML.range(of: "discuz_uid\\s*=\\s*(\\d+)", options: .regularExpression) {
                let uidStr = String(decodedHTML[uidRange])
                    .replacingOccurrences(of: "discuz_uid", with: "")
                    .replacingOccurrences(of: "=", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                extractedUid = Int(uidStr) ?? 0
            } else {
                extractedUid = defaultUid
            }

            // Extract avatar
            var avatar: String?
            if let avatarRange = decodedHTML.range(of: "class=\"avatar\"[^>]*>\\s*<img[^>]+src=\"([^\"]+)\"", options: .regularExpression) {
                let match = String(decodedHTML[avatarRange])
                if let srcRange = match.range(of: "src=\"([^\"]+)\"", options: .regularExpression) {
                    avatar = String(match[srcRange])
                        .replacingOccurrences(of: "src=\"", with: "")
                        .replacingOccurrences(of: "\"", with: "")
                }
            }

            // Check online status
            let isOnline = decodedHTML.contains("online_buddy.gif")

            // Extract gender
            var gender: String?
            if decodedHTML.contains("性别:</th>") || decodedHTML.contains("性别:") {
                if decodedHTML.contains(">男<") || decodedHTML.contains("男</td>") {
                    gender = "男"
                } else if decodedHTML.contains(">女<") || decodedHTML.contains("女</td>") {
                    gender = "女"
                }
            }

            // Extract QQ
            var qq: String?
            if let qqRange = decodedHTML.range(of: "Uin=(\\d+)&", options: .regularExpression) {
                let match = String(decodedHTML[qqRange])
                    .replacingOccurrences(of: "Uin=", with: "")
                    .replacingOccurrences(of: "&", with: "")
                qq = match.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Extract user group
            var userGroup = "初级会员"
            if let groupRange = decodedHTML.range(of: "用户组:\\s*<a[^>]+>([^<]+)</a>", options: .regularExpression) {
                let match = String(decodedHTML[groupRange])
                if let linkRange = match.range(of: ">([^<]+)<", options: .regularExpression) {
                    userGroup = String(match[linkRange])
                        .replacingOccurrences(of: ">", with: "")
                        .replacingOccurrences(of: "<", with: "")
                }
            }

            // Extract registration date
            var registrationDate: String?
            if let regRange = decodedHTML.range(of: "注册日期:\\s*(\\d{4}-\\d{2}-\\d{2})", options: .regularExpression) {
                let match = String(decodedHTML[regRange])
                registrationDate = match.replacingOccurrences(of: "注册日期:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Extract last visit
            var lastVisitDate: String?
            if let visitRange = decodedHTML.range(of: "上次访问:\\s*(\\d{4}-\\d{2}-\\d{2}\\s+\\d{2}:\\d{2})", options: .regularExpression) {
                let match = String(decodedHTML[visitRange])
                lastVisitDate = match.replacingOccurrences(of: "上次访问:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Extract last post
            var lastPostDate: String?
            if let postRange = decodedHTML.range(of: "最后发表:\\s*(\\d{4}-\\d{2}-\\d{2}\\s+\\d{2}:\\d{2})", options: .regularExpression) {
                let match = String(decodedHTML[postRange])
                lastPostDate = match.replacingOccurrences(of: "最后发表:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Extract post level
            var postLevel: String?
            if let levelRange = decodedHTML.range(of: "发帖数级别:\\s*([^<\\n]+)", options: .regularExpression) {
                let match = String(decodedHTML[levelRange])
                postLevel = match.replacingOccurrences(of: "发帖数级别:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                // Clean up star images
                postLevel = postLevel?.replacingOccurrences(of: "<img[^>]+>", with: "", options: .regularExpression)
                postLevel = postLevel?.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            // Extract read permission
            var readPermission = 0
            if let permRange = decodedHTML.range(of: "阅读权限:\\s*(\\d+)", options: .regularExpression) {
                let match = String(decodedHTML[permRange])
                let permStr = match.replacingOccurrences(of: "阅读权限:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                readPermission = Int(permStr) ?? 0
            }

            // Extract total posts
            var totalPosts = 0
            if let postsRange = decodedHTML.range(of: "帖子:\\s*(\\d+)", options: .regularExpression) {
                let match = String(decodedHTML[postsRange])
                let postsStr = match.replacingOccurrences(of: "帖子:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                totalPosts = Int(postsStr) ?? 0
            }

            // Extract daily average
            var dailyAveragePosts: Double = 0
            if let avgRange = decodedHTML.range(of: "平均每日发帖:\\s*([\\d.]+)", options: .regularExpression) {
                let match = String(decodedHTML[avgRange])
                let avgStr = match.replacingOccurrences(of: "平均每日发帖:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                dailyAveragePosts = Double(avgStr) ?? 0
            }

            // Extract essence posts
            var essencePosts = 0
            if let essenceRange = decodedHTML.range(of: "精华:\\s*(\\d+)", options: .regularExpression) {
                let match = String(decodedHTML[essenceRange])
                let essenceStr = match.replacingOccurrences(of: "精华:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                essencePosts = Int(essenceStr) ?? 0
            }

            // Extract page views
            var pageViews = 0
            if let viewsRange = decodedHTML.range(of: "页面访问量:\\s*([\\d,]+)", options: .regularExpression) {
                let match = String(decodedHTML[viewsRange])
                let viewsStr = match.replacingOccurrences(of: "页面访问量:", with: "").replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                pageViews = Int(viewsStr) ?? 0
            }

            // Extract online hours
            var totalOnlineHours: Double = 0
            if let totalRange = decodedHTML.range(of: "总计在线\\s*<em>([\\d.]+)</em>", options: .regularExpression) {
                let match = String(decodedHTML[totalRange])
                let hoursStr = match.replacingOccurrences(of: "总计在线", with: "").replacingOccurrences(of: "<em>", with: "").replacingOccurrences(of: "</em>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                totalOnlineHours = Double(hoursStr) ?? 0
            }

            var monthOnlineHours: Double = 0
            if let monthRange = decodedHTML.range(of: "本月在线\\s*<em>([\\d.]+)</em>", options: .regularExpression) {
                let match = String(decodedHTML[monthRange])
                let hoursStr = match.replacingOccurrences(of: "本月在线", with: "").replacingOccurrences(of: "<em>", with: "").replacingOccurrences(of: "</em>", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                monthOnlineHours = Double(hoursStr) ?? 0
            }

            // Extract credits
            var credits = 0
            if let creditRange = decodedHTML.range(of: "积分:\\s*(\\d+)", options: .regularExpression) {
                let match = String(decodedHTML[creditRange])
                let creditStr = match.replacingOccurrences(of: "积分:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                credits = Int(creditStr) ?? 0
            }

            var prestige = 0
            if let presRange = decodedHTML.range(of: "威望:\\s*(\\d+)", options: .regularExpression) {
                let match = String(decodedHTML[presRange])
                let presStr = match.replacingOccurrences(of: "威望:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                prestige = Int(presStr) ?? 0
            }

            var money = 0
            if let moneyRange = decodedHTML.range(of: "金钱:\\s*(\\d+)", options: .regularExpression) {
                let match = String(decodedHTML[moneyRange])
                let moneyStr = match.replacingOccurrences(of: "金钱:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                money = Int(moneyStr) ?? 0
            }

            return ForumUser(
                uid: extractedUid,
                username: username,
                avatar: avatar,
                isOnline: isOnline,
                gender: gender,
                qq: qq,
                msn: nil,
                userGroup: userGroup,
                registrationDate: registrationDate,
                lastVisitDate: lastVisitDate,
                lastPostDate: lastPostDate,
                registrationIP: nil,
                lastVisitIP: nil,
                postLevel: postLevel,
                readPermission: readPermission,
                totalPosts: totalPosts,
                dailyAveragePosts: dailyAveragePosts,
                essencePosts: essencePosts,
                pageViews: pageViews,
                totalOnlineHours: totalOnlineHours,
                monthOnlineHours: monthOnlineHours,
                credits: credits,
                prestige: prestige,
                money: money,
                sellerCredit: 0,
                buyerCredit: 0
            )
        } catch {
            print("[Profile] Failed to parse HTML: \(error)")
            return nil
        }
    }

    private func updateUIWithProfile(_ profile: ForumUser) {
        usernameLabel.text = profile.username
        uidLabel.text = "UID: \(profile.uid)"

        if profile.isOnline {
            onlineStatusView.backgroundColor = UIColor.systemGreen
            onlineStatusLabel.text = "在线"
        } else {
            onlineStatusView.backgroundColor = Theme.muted
            onlineStatusLabel.text = "离线"
        }

        postsCountLabel.text = "\(profile.totalPosts)"
        creditsCountLabel.text = "\(profile.credits)"

        if let avatarUrl = profile.avatar, let url = URL(string: avatarUrl) {
            loadImage(from: url, into: avatarImageView)
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
        }

        updateInfoCard(with: profile)
    }

    private func loadImage(from url: URL, into imageView: UIImageView) {
        URLSession.shared.dataTask(with: url) { [weak imageView] data, _, error in
            if let data = data, error == nil, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    imageView?.image = image
                }
            }
        }.resume()
    }

    @objc private func loginTapped() {
        let loginVC = LoginViewController()
        loginVC.delegate = self
        let navController = UINavigationController(rootViewController: loginVC)
        present(navController, animated: true)
    }

    // MARK: - LoginViewControllerDelegate

    func loginViewControllerDidLogin(_ controller: LoginViewController) {
        print("[Profile] Login completed, refreshing data...")
        loadUserData()
    }

    func loginViewControllerDidLoginWithForumData(_ controller: LoginViewController, forums: [Forum]) {
        print("[Profile] Login with forum data completed, refreshing data...")
        loadUserData()
    }

    func loginViewControllerDidCancel(_ controller: LoginViewController) {
        print("[Profile] Login cancelled")
    }

    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "退出登录", message: "确定要退出登录吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "确定", style: .destructive) { [weak self] _ in
            LoginManager.shared.clearCredentials()
            self?.updateUIForLoggedOut()
        })
        present(alert, animated: true)
    }
}

// MARK: - WKNavigationDelegate

extension ProfileViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let urlString = webView.url?.absoluteString ?? ""
        print("[Profile] WKWebView loaded: \(urlString)")

        // If currentFetchingUid is 0, we're fetching UID from memcp.php
        if currentFetchingUid == 0 && urlString.contains("memcp.php") {
            // Extract UID from memcp.php
            let js = """
            (function() {
                var links = document.querySelectorAll('a[href*="space.php?uid="]');
                for (var i = 0; i < links.length; i++) {
                    var href = links[i].getAttribute('href');
                    var match = href.match(/uid=(\\d+)/);
                    if (match && match[1]) {
                        return match[1];
                    }
                }
                return null;
            })();
            """

            webView.evaluateJavaScript(js) { [weak self] result, error in
                guard let self = self else { return }

                print("[Profile] UID extraction result: \(result ?? "nil")")

                if let uidStr = result as? String, let uid = Int(uidStr) {
                    print("[Profile] Extracted UID: \(uid)")
                    LoginManager.shared.uid = uid
                    self.currentFetchingUid = uid
                    self.updateUIForLoggedIn(username: LoginManager.shared.username ?? "用户", uid: uid)
                    // Now fetch the profile
                    self.fetchProfileWithWKWebView(uid: uid)
                } else {
                    print("[Profile] Failed to extract UID")
                    self.isLoading = false
                    self.profileWebView?.removeFromSuperview()
                    self.profileWebView = nil
                    self.onlineStatusLabel.text = "加载失败"
                }
            }
            return
        }

        if urlString.contains("space.php?uid=") {
            // Extract HTML from page
            webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, error in
                guard let self = self else { return }

                self.isLoading = false
                self.profileWebView?.removeFromSuperview()
                self.profileWebView = nil

                if let html = result as? String {
                    print("[Profile] Got HTML length: \(html.count)")

                    if let profile = self.parseProfileHTML(html, defaultUid: self.currentFetchingUid) {
                        print("[Profile] Parsed profile successfully!")
                        print("[Profile] username: \(profile.username)")
                        print("[Profile] uid: \(profile.uid)")
                        print("[Profile] totalPosts: \(profile.totalPosts)")
                        print("[Profile] credits: \(profile.credits)")

                        self.userProfile = profile
                        self.updateUIWithProfile(profile)
                    } else {
                        print("[Profile] Failed to parse profile")
                        self.onlineStatusLabel.text = "加载失败"
                    }
                } else {
                    print("[Profile] Failed to get HTML: \(error?.localizedDescription ?? "unknown")")
                    self.onlineStatusLabel.text = "加载失败"
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[Profile] WKWebView failed: \(error.localizedDescription)")
        isLoading = false
        profileWebView?.removeFromSuperview()
        profileWebView = nil
        onlineStatusLabel.text = "加载失败"
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        // Ignore cancelled errors
        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled {
            return
        }
        print("[Profile] WKWebView provisional failed: \(error.localizedDescription)")
        isLoading = false
        profileWebView?.removeFromSuperview()
        profileWebView = nil
        onlineStatusLabel.text = "加载失败"
    }
}
