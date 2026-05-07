import UIKit

class ThreadDetailViewController: UIViewController {

    private let thread: ForumThread
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var posts: [ForumPost] = []
    private var currentPage = 1
    private var totalPages = 1
    private var isLoading = false
    private var formhash: String?
    private var paginationPrefetcher: PaginationPrefetcher?
    private var lastScrollPercentage: CGFloat = 0

    init(thread: ForumThread) {
        self.thread = thread
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadThreadDetail()
        loadFormhash()

        // Initialize pagination prefetcher
        paginationPrefetcher = PaginationPrefetcher(tid: thread.tid)
        ImagePrefetchManager.shared.prefetchImages(for: thread.tid, imageURLs: [])

        // Mark thread as read
        ReadTracker.shared.markAsRead(tid: thread.tid)
    }

    private func setupUI() {
        title = thread.displayTitle
        view.backgroundColor = Theme.background

        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.card
        appearance.titleTextAttributes = [.foregroundColor: Theme.foreground]
        appearance.largeTitleTextAttributes = [.foregroundColor: Theme.foreground]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.identifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = Theme.background
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = Theme.primary
        refreshControl.addTarget(self, action: #selector(refreshPosts), for: .valueChanged)
        tableView.refreshControl = refreshControl

        let replyButton = UIButton(type: .system)
        replyButton.setTitle("回复", for: .normal)
        replyButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        replyButton.tintColor = Theme.primary
        replyButton.addTarget(self, action: #selector(showReply), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: replyButton)
    }

    private func loadThreadDetail() {
        guard !isLoading else { return }
        isLoading = true

        print("[ThreadDetail] Loading thread detail:")
        print("[ThreadDetail]   thread.tid: \(thread.tid)")
        print("[ThreadDetail]   thread.title: \(thread.title)")
        print("[ThreadDetail]   thread.displayTitle: \(thread.displayTitle)")
        let pageString = currentPage > 1 ? "&page=\(currentPage)" : ""
        print("[ThreadDetail]   URL: https://www.4d4y.com/forum/viewthread.php?tid=\(thread.tid)&highlight=\(pageString)")

        Task {
            do {
                let detail = try await NetworkManager.shared.fetchThreadDetail(tid: thread.tid, page: currentPage)
                await MainActor.run {
                    self.isLoading = false
                    self.refreshControl?.endRefreshing()

                    if self.currentPage == 1 {
                        self.posts = detail.posts
                    } else {
                        self.posts.append(contentsOf: detail.posts)
                    }

                    self.totalPages = detail.totalPages
                    self.title = detail.title.isEmpty ? self.thread.displayTitle : detail.title
                    self.tableView.reloadData()

                    // Start prefetching next pages
                    self.paginationPrefetcher?.prefetchNextPages(currentPage: self.currentPage, totalPages: self.totalPages)

                    // Prefetch images for current page
                    let allImages = detail.posts.flatMap { $0.images }
                    ImagePrefetchManager.shared.prefetchImages(for: self.thread.tid, imageURLs: allImages)
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.refreshControl?.endRefreshing()
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func loadFormhash() {
        Task {
            do {
                let loginData = try await NetworkManager.shared.fetchLoginPage()
                await MainActor.run {
                    self.formhash = loginData.formhash
                }
            } catch {
                // Ignore formhash fetch error
            }
        }
    }

    @objc private func refreshPosts() {
        currentPage = 1
        loadThreadDetail()
    }

    @objc private func showReply() {
        guard LoginManager.shared.isLoggedIn else {
            showLoginAlert()
            return
        }

        let replyVC = ReplyViewController(tid: thread.tid)
        replyVC.delegate = self
        let navController = UINavigationController(rootViewController: replyVC)
        present(navController, animated: true)
    }

    private func submitReply(message: String, formhash: String) {
        Task {
            do {
                let success = try await NetworkManager.shared.replyThread(
                    tid: thread.tid,
                    message: message,
                    formhash: formhash
                )
                await MainActor.run {
                    if success {
                        self.showAlert(title: "成功", message: "回复已发送")
                        self.refreshPosts()
                    } else {
                        self.showAlert(title: "失败", message: "回复发送失败")
                    }
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "错误", message: error.localizedDescription)
                }
            }
        }
    }

    private func showLoginAlert() {
        let alert = UIAlertController(
            title: "需要登录",
            message: "请先登录后再进行操作",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "登录", style: .default) { [weak self] _ in
            self?.showLogin()
        })
        present(alert, animated: true)
    }

    private func showLogin() {
        let loginVC = LoginViewController()
        loginVC.delegate = self
        let navController = UINavigationController(rootViewController: loginVC)
        present(navController, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "加载失败", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private var refreshControl: UIRefreshControl? {
        return tableView.refreshControl
    }
}

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent {
            paginationPrefetcher?.clear()
            ImagePrefetchManager.shared.cancelPrefetch(for: thread.tid)
        }
    }

extension ThreadDetailViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.identifier, for: indexPath) as? PostCell else {
            return UITableViewCell()
        }

        let post = posts[indexPath.row]
        cell.configure(with: post)
        cell.delegate = self
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        // Calculate scroll percentage
        let scrollPercentage = contentHeight > 0 ? offsetY / (contentHeight - height) : 0

        // Check if prefetch callback exists for next page
        if offsetY > contentHeight - height - 100 && !isLoading && currentPage < totalPages {
            let nextPage = currentPage + 1

            // Check if we already have this page prefetched
            if let prefetched = paginationPrefetcher?.getPrefetchedPage(nextPage) {
                // Use prefetched data
                currentPage += 1
                posts.append(contentsOf: prefetched.posts)
                tableView.reloadData()
            } else {
                // Fetch normally
                currentPage += 1
                loadThreadDetail()
            }
        }

        // Trigger prefetch at scroll milestones
        if scrollPercentage > 0.5 && lastScrollPercentage <= 0.5 {
            // Crossed 50% threshold
            paginationPrefetcher?.prefetchPage(currentPage + 1)
        } else if scrollPercentage > 0.75 && lastScrollPercentage <= 0.75 {
            // Crossed 75% threshold
            paginationPrefetcher?.prefetchPage(currentPage + 2)
        }

        lastScrollPercentage = scrollPercentage
    }
}

// MARK: - PostCellDelegate

extension ThreadDetailViewController: PostCellDelegate {
    func postCellDidTapReply(_ cell: PostCell, post: ForumPost) {
        guard LoginManager.shared.isLoggedIn else {
            showLoginAlert()
            return
        }

        let replyVC = ReplyViewController(tid: thread.tid, reppost: post.pid)
        replyVC.delegate = self
        let navController = UINavigationController(rootViewController: replyVC)
        present(navController, animated: true)
    }
}

// MARK: - ReplyViewControllerDelegate

extension ThreadDetailViewController: ReplyViewControllerDelegate {
    func replyViewControllerDidPost(_ controller: ReplyViewController) {
        showAlert(title: "成功", message: "回复已发送")
        refreshPosts()
    }

    func replyViewControllerDidCancel(_ controller: ReplyViewController) {
        // Nothing to do
    }
}

// MARK: - LoginViewControllerDelegate

extension ThreadDetailViewController: LoginViewControllerDelegate {
    func loginViewControllerDidLogin(_ controller: LoginViewController) {
        print("[ThreadDetail] Login completed, refreshing posts...")
        refreshPosts()
    }

    func loginViewControllerDidLoginWithForumData(_ controller: LoginViewController, forums: [Forum]) {
        print("[ThreadDetail] Login with forum data completed, refreshing posts...")
        refreshPosts()
    }

    func loginViewControllerDidCancel(_ controller: LoginViewController) {
        // Nothing to do
    }
}
