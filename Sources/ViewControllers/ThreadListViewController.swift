import UIKit

class ThreadListViewController: UIViewController {

    private let forum: Forum
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private var threads: [ForumThread] = []
    private var currentPage = 1
    private var totalPages = 1
    private var isLoading = false
    private var loadError: Error?

    init(forum: Forum) {
        self.forum = forum
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadThreads()
    }

    private func setupUI() {
        title = forum.displayName
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
        tableView.register(ThreadCell.self, forCellReuseIdentifier: ThreadCell.identifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = Theme.background
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
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
        refreshControl.addTarget(self, action: #selector(refreshThreads), for: .valueChanged)
        tableView.refreshControl = refreshControl

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "发帖",
            style: .plain,
            target: self,
            action: #selector(createNewThread)
        )
        navigationItem.rightBarButtonItem?.tintColor = Theme.primary

        emptyLabel.text = "暂无帖子\n下拉刷新获取最新内容"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = Theme.secondaryText
        emptyLabel.font = .systemFont(ofSize: 15)
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])

        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.color = Theme.primary
        view.addSubview(loadingIndicator)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func loadThreads() {
        guard !isLoading else { return }
        isLoading = true
        loadError = nil

        if currentPage == 1 && threads.isEmpty {
            loadingIndicator.startAnimating()
        }

        Task {
            do {
                let fetchedThreads = try await NetworkManager.shared.fetchThreadList(fid: forum.fid, page: currentPage)
                await MainActor.run {
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl?.endRefreshing()

                    if self.currentPage == 1 {
                        self.threads = fetchedThreads
                    } else {
                        self.threads.append(contentsOf: fetchedThreads)
                    }

                    self.updateEmptyState()
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loadingIndicator.stopAnimating()
                    self.refreshControl?.endRefreshing()
                    self.loadError = error
                    self.updateEmptyState()
                    self.tableView.reloadData()
                }
            }
        }
    }

    private func updateEmptyState() {
        if threads.isEmpty {
            if let error = loadError {
                emptyLabel.text = "加载失败\n\(error.localizedDescription)\n\n下拉重试"
            } else {
                emptyLabel.text = "暂无帖子\n下拉刷新获取最新内容"
            }
            emptyLabel.isHidden = false
        } else {
            emptyLabel.isHidden = true
        }
    }

    private func loadLocalThreads() {
        updateEmptyState()
        tableView.reloadData()
    }

    @objc private func refreshThreads() {
        currentPage = 1
        loadThreads()
    }

    @objc private func createNewThread() {
        guard LoginManager.shared.isLoggedIn else {
            showLoginAlert()
            return
        }

        let newThreadVC = NewThreadViewController(fid: forum.fid)
        newThreadVC.delegate = self
        let navController = UINavigationController(rootViewController: newThreadVC)
        present(navController, animated: true)
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

    private var refreshControl: UIRefreshControl? {
        return tableView.refreshControl
    }
}

extension ThreadListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return threads.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ThreadCell.identifier, for: indexPath) as? ThreadCell else {
            return UITableViewCell()
        }

        let thread = threads[indexPath.row]
        cell.configure(with: thread)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let thread = threads[indexPath.row]
        ReadTracker.shared.markAsRead(tid: thread.tid)
        tableView.reloadRows(at: [indexPath], with: .none)

        let detailVC = ThreadDetailViewController(thread: thread)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height

        if offsetY > contentHeight - height - 100 && !isLoading && currentPage < totalPages {
            currentPage += 1
            loadThreads()
        }
    }
}

extension ThreadListViewController: NewThreadViewControllerDelegate {
    func newThreadViewControllerDidPost(_ controller: NewThreadViewController) {
        refreshThreads()
    }
}

extension ThreadListViewController: LoginViewControllerDelegate {
    func loginViewControllerDidLogin(_ controller: LoginViewController) {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    func loginViewControllerDidLoginWithForumData(_ controller: LoginViewController, forums: [Forum]) {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }

    func loginViewControllerDidCancel(_ controller: LoginViewController) {
    }
}
