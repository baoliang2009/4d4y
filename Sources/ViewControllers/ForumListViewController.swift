import UIKit

class ForumListViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private var forums: [Forum] = []
    private var favoriteForums: [Forum] = []
    private var isShowingFavorites = false

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadForums()
    }

    private func setupUI() {
        title = "FourD4Y"
        view.backgroundColor = Theme.currentBackground

        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.currentCard
        appearance.titleTextAttributes = [.foregroundColor: Theme.currentForeground]
        appearance.largeTitleTextAttributes = [.foregroundColor: Theme.currentForeground]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ForumCell.self, forCellReuseIdentifier: ForumCell.identifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = Theme.currentBackground
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

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "收藏",
            style: .plain,
            target: self,
            action: #selector(toggleForumList)
        )
        navigationItem.rightBarButtonItem?.tintColor = Theme.primary

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "登录",
            style: .plain,
            target: self,
            action: #selector(showLogin)
        )
        navigationItem.leftBarButtonItem?.tintColor = Theme.primary

        let refreshControl = UIRefreshControl()
        refreshControl.tintColor = Theme.primary
        refreshControl.addTarget(self, action: #selector(refreshForums), for: .valueChanged)
        tableView.refreshControl = refreshControl

        emptyLabel.text = "暂无收藏版块\n点击右上角切换到全部版块"
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = Theme.currentSecondaryText
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
    }

    private func loadForums() {
        favoriteForums = ForumManager.shared.favoriteForums
        forums = ForumManager.shared.allForums
        updateEmptyState()
        tableView.reloadData()
    }

    private func updateEmptyState() {
        let currentForums = isShowingFavorites ? favoriteForums : forums
        emptyLabel.isHidden = !currentForums.isEmpty

        if isShowingFavorites && favoriteForums.isEmpty {
            emptyLabel.text = "暂无收藏版块\n点击右上角切换到全部版块"
        } else if !isShowingFavorites && forums.isEmpty {
            emptyLabel.text = "暂无法块数据\n下拉刷新获取最新内容"
        }
    }

    @objc private func refreshForums() {
        Task {
            do {
                let fetchedForums = try await NetworkManager.shared.fetchForumList()
                await MainActor.run {
                    if !fetchedForums.isEmpty {
                        self.forums = fetchedForums
                    }
                    self.tableView.refreshControl?.endRefreshing()
                    self.updateEmptyState()
                    self.tableView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.tableView.refreshControl?.endRefreshing()
                    self.loadForums()
                }
            }
        }
    }

    @objc private func toggleForumList() {
        isShowingFavorites.toggle()
        navigationItem.rightBarButtonItem?.title = isShowingFavorites ? "全部" : "收藏"
        updateEmptyState()
        tableView.reloadData()
    }

    @objc private func showLogin() {
        let loginVC = LoginViewController()
        loginVC.delegate = self
        let navController = UINavigationController(rootViewController: loginVC)
        present(navController, animated: true)
    }

    private var currentForums: [Forum] {
        return isShowingFavorites ? favoriteForums : forums
    }
}

extension ForumListViewController: UITableViewDataSource, UITableViewDelegate {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentForums.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return isShowingFavorites ? "收藏版块" : "全部版块"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ForumCell.identifier, for: indexPath) as? ForumCell else {
            return UITableViewCell()
        }

        let forum = currentForums[indexPath.row]
        cell.configure(with: forum)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let forum = currentForums[indexPath.row]
        ForumManager.shared.updateLastVisited(fid: forum.fid)

        let threadListVC = ThreadListViewController(forum: forum)
        navigationController?.pushViewController(threadListVC, animated: true)
    }
}

extension ForumListViewController: LoginViewControllerDelegate {
    func loginViewControllerDidLogin(_ controller: LoginViewController) {
        navigationItem.leftBarButtonItem?.title = LoginManager.shared.username ?? "登录"
        // Refresh forum list after login (new forums may be available)
        refreshForums()
    }

    func loginViewControllerDidLoginWithForumData(_ controller: LoginViewController, forums: [Forum]) {
        navigationItem.leftBarButtonItem?.title = LoginManager.shared.username ?? "登录"
        // Use the forum data received from WKWebView
        if !forums.isEmpty {
            self.forums = forums
            self.tableView.reloadData()
            self.updateEmptyState()
        } else {
            // Fallback to network fetch if no forums received
            refreshForums()
        }
    }

    func loginViewControllerDidCancel(_ controller: LoginViewController) {
    }
}
