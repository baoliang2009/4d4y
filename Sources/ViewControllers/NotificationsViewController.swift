import UIKit
import WebKit
import SDWebImage

class NotificationsViewController: UIViewController {

    private let tableView = UITableView()
    private let emptyView = UIView()
    private let emptyIconView = UIImageView()
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var webView: WKWebView?
    private var privateMessages: [PrivateMessage] = []
    private var replyNotifications: [NotificationItem] = []

    // Section indices
    private let sectionPMs = 0
    private let sectionReplies = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPrivateMessages()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPrivateMessages()
    }

    private func setupUI() {
        title = "消息"
        view.backgroundColor = Theme.currentBackground

        setupTableView()
        setupEmptyState()
        setupLoadingIndicator()
    }

    private func setupTableView() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PMCell.self, forCellReuseIdentifier: PMCell.identifier)
        tableView.register(NotificationCell.self, forCellReuseIdentifier: NotificationCell.identifier)
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupEmptyState() {
        emptyView.isHidden = true
        view.addSubview(emptyView)

        emptyIconView.image = UIImage(systemName: "bell.slash")
        emptyIconView.tintColor = Theme.currentSecondaryText
        emptyIconView.contentMode = .scaleAspectFit
        emptyView.addSubview(emptyIconView)

        emptyLabel.text = "暂无新消息"
        emptyLabel.font = .systemFont(ofSize: 16)
        emptyLabel.textColor = Theme.currentSecondaryText
        emptyLabel.textAlignment = .center
        emptyView.addSubview(emptyLabel)

        emptyView.translatesAutoresizingMaskIntoConstraints = false
        emptyIconView.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            emptyView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),

            emptyIconView.topAnchor.constraint(equalTo: emptyView.topAnchor),
            emptyIconView.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyIconView.widthAnchor.constraint(equalToConstant: 80),
            emptyIconView.heightAnchor.constraint(equalToConstant: 80),

            emptyLabel.topAnchor.constraint(equalTo: emptyIconView.bottomAnchor, constant: 16),
            emptyLabel.centerXAnchor.constraint(equalTo: emptyView.centerXAnchor),
            emptyLabel.bottomAnchor.constraint(equalTo: emptyView.bottomAnchor)
        ])
    }

    private func setupLoadingIndicator() {
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = Theme.primary
        view.addSubview(loadingIndicator)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadPrivateMessages() {
        guard LoginManager.shared.isLoggedIn else {
            showEmptyState(message: "请先登录")
            return
        }

        loadingIndicator.startAnimating()
        emptyView.isHidden = true

        // Create hidden WKWebView to handle Cloudflare
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36"
        webView.navigationDelegate = self
        webView.isHidden = true
        self.webView = webView
        view.addSubview(webView)

        let pmURL = URL(string: "https://www.4d4y.com/forum/pm.php?filter=privatepm")!
        webView.load(URLRequest(url: pmURL))

        print("[Notifications] Loading PM list via WKWebView...")
    }

    private func extractPMList() {
        guard let webView = webView else { return }

        let js = "document.documentElement.outerHTML"
        webView.evaluateJavaScript(js) { [weak self] result, error in
            if let error = error {
                print("[Notifications] JS error: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                }
                return
            }

            guard let html = result as? String else {
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                }
                return
            }

            // Parse HTML using ForumHTMLParser
            do {
                if let data = html.data(using: .utf8) {
                    let messages = try ForumHTMLParser.parsePrivateMessages(data)
                    DispatchQueue.main.async {
                        self?.loadingIndicator.stopAnimating()
                        self?.privateMessages = messages
                        self?.tableView.reloadData()
                        self?.updateEmptyState()
                    }
                } else {
                    // Try GB18030 encoding for Chinese websites
                    let gbEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(0x80000631)))
                    if let data = html.data(using: gbEncoding) {
                        let messages = try ForumHTMLParser.parsePrivateMessages(data)
                        DispatchQueue.main.async {
                            self?.loadingIndicator.stopAnimating()
                            self?.privateMessages = messages
                            self?.tableView.reloadData()
                            self?.updateEmptyState()
                        }
                    }
                }
            } catch {
                print("[Notifications] Parse error: \(error)")
                DispatchQueue.main.async {
                    self?.loadingIndicator.stopAnimating()
                    self?.showEmptyState(message: "加载失败")
                }
            }
        }
    }

    private func updateEmptyState() {
        if privateMessages.isEmpty && replyNotifications.isEmpty {
            showEmptyState(message: "暂无新消息")
        } else {
            emptyView.isHidden = true
        }
    }

    private func showEmptyState(message: String) {
        emptyLabel.text = message
        emptyView.isHidden = false
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension NotificationsViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case sectionPMs:
            return privateMessages.count
        case sectionReplies:
            return replyNotifications.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case sectionPMs:
            return privateMessages.isEmpty ? nil : "私信"
        case sectionReplies:
            return replyNotifications.isEmpty ? nil : "回复"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case sectionPMs:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: PMCell.identifier, for: indexPath) as? PMCell else {
                return UITableViewCell()
            }
            let pm = privateMessages[indexPath.row]
            cell.configure(with: pm)
            return cell
        case sectionReplies:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: NotificationCell.identifier, for: indexPath) as? NotificationCell else {
                return UITableViewCell()
            }
            let notification = replyNotifications[indexPath.row]
            cell.configure(with: notification)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case sectionPMs:
            let pm = privateMessages[indexPath.row]
            let pmDetailVC = PMDetailViewController(uid: pm.fromUid, username: pm.fromUsername)
            navigationController?.pushViewController(pmDetailVC, animated: true)
        case sectionReplies:
            let notification = replyNotifications[indexPath.row]
            // Handle reply notification tap - TODO: implement
            print("[Notifications] Reply notification tapped: \(notification.title)")
        default:
            break
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case sectionPMs:
            return 92
        case sectionReplies:
            return 72
        default:
            return 80
        }
    }
}

// MARK: - WKNavigationDelegate

extension NotificationsViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let urlString = webView.url?.absoluteString ?? ""
        print("[Notifications] Page loaded: \(urlString)")

        // Extract content after page finishes loading
        extractPMList()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: any Error) {
        print("[Notifications] Load failed: \(error.localizedDescription)")
        DispatchQueue.main.async {
            self.loadingIndicator.stopAnimating()
            self.showEmptyState(message: "加载失败")
        }
    }
}
