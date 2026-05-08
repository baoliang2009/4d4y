import UIKit

class AccountSwitcherViewController: UIViewController {
    private let tableView = UITableView()
    private let headerView = UIView()
    private let titleLabel = UILabel()
    private let addButton = UIButton(type: .system)

    private var accounts: [Account] = []
    private var currentAccountId: UUID?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAccounts()
    }

    private func setupUI() {
        view.backgroundColor = Theme.currentBackground

        // Header
        titleLabel.text = "切换账号"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = Theme.currentForeground
        titleLabel.textAlignment = .center

        addButton.setTitle("添加新账号", for: .normal)
        addButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        addButton.tintColor = Theme.primary
        addButton.addTarget(self, action: #selector(addAccountTapped), for: .touchUpInside)

        headerView.addSubview(titleLabel)
        headerView.addSubview(addButton)
        view.addSubview(headerView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addButton.translatesAutoresizingMaskIntoConstraints = false
        headerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 60),

            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),

            addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])

        // TableView
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Theme.currentBorder
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(AccountCell.self, forCellReuseIdentifier: AccountCell.identifier)
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func loadAccounts() {
        accounts = AccountManager.shared.accounts
        currentAccountId = AccountManager.shared.currentAccountId
        tableView.reloadData()
    }

    @objc private func addAccountTapped() {
        let addVC = AddAccountViewController()
        addVC.delegate = self
        let navController = UINavigationController(rootViewController: addVC)
        present(navController, animated: true)
    }
}

// MARK: - UITableViewDataSource

extension AccountSwitcherViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return accounts.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: AccountCell.identifier, for: indexPath) as? AccountCell else {
            return UITableViewCell()
        }

        let account = accounts[indexPath.row]
        cell.configure(with: account, isCurrent: account.id == currentAccountId)
        return cell
    }
}

// MARK: - UITableViewDelegate

extension AccountSwitcherViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let account = accounts[indexPath.row]
        AccountManager.shared.switchAccount(id: account.id)
        dismiss(animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let account = accounts[indexPath.row]

        // Don't allow deleting the only account
        guard accounts.count > 1 else { return nil }

        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] _, _, completion in
            AccountManager.shared.removeAccount(id: account.id)
            self?.loadAccounts()
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: - AddAccountViewControllerDelegate

extension AccountSwitcherViewController: AddAccountViewControllerDelegate {
    func addAccountViewControllerDidAddAccount(_ controller: AddAccountViewController) {
        loadAccounts()
    }
}
