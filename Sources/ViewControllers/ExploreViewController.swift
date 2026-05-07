import UIKit

class ExploreViewController: UIViewController {

    private let searchBar = UISearchBar()
    private let tableView = UITableView(frame: .zero, style: .plain)

    private var forums: [Forum] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadForums()
    }

    private func setupUI() {
        title = "探索"
        view.backgroundColor = Theme.currentBackground

        // Search bar
        searchBar.placeholder = "搜索版块..."
        searchBar.searchBarStyle = .minimal
        searchBar.barTintColor = Theme.currentBackground
        searchBar.tintColor = Theme.primary
        if let textField = searchBar.value(forKey: "searchField") as? UITextField {
            textField.textColor = Theme.currentForeground
            textField.backgroundColor = Theme.currentMuted
        }
        searchBar.delegate = self
        view.addSubview(searchBar)

        // Table view
        tableView.backgroundColor = Theme.currentBackground
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ForumCell.self, forCellReuseIdentifier: ForumCell.identifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        view.addSubview(tableView)

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),

            tableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadForums() {
        Task {
            do {
                let fetchedForums = try await NetworkManager.shared.fetchForumList()
                await MainActor.run {
                    self.forums = fetchedForums
                    self.tableView.reloadData()
                }
            } catch {
                print("Failed to load forums: \(error)")
            }
        }
    }

    private func filterForums(with query: String) -> [Forum] {
        if query.isEmpty {
            return forums
        }
        return forums.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ExploreViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterForums(with: searchBar.text ?? "").count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ForumCell.identifier, for: indexPath) as? ForumCell else {
            return UITableViewCell()
        }

        let filteredForums = filterForums(with: searchBar.text ?? "")
        cell.configure(with: filteredForums[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let filteredForums = filterForums(with: searchBar.text ?? "")
        let forum = filteredForums[indexPath.row]

        let threadListVC = ThreadListViewController(forum: forum)
        navigationController?.pushViewController(threadListVC, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension ExploreViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}
