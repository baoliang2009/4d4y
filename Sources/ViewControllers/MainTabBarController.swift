import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupViewControllers()
    }

    private func setupAppearance() {
        // Tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.card

        // Normal state
        appearance.stackedLayoutAppearance.normal.iconColor = Theme.secondaryText
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: Theme.secondaryText]

        // Selected state
        appearance.stackedLayoutAppearance.selected.iconColor = Theme.primary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: Theme.primary]

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = Theme.primary

        // Add top border
        tabBar.layer.borderWidth = 0.5
        tabBar.layer.borderColor = Theme.border.cgColor
    }

    private func setupViewControllers() {
        // Home - Forum Home with hot topics and categories
        let homeVC = HomeViewController()
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(
            title: "首页",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        configureNavigationBar(homeNav)

        // Explore - Search
        let searchVC = SearchViewController()
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.tabBarItem = UITabBarItem(
            title: "探索",
            image: UIImage(systemName: "magnifyingglass"),
            selectedImage: UIImage(systemName: "magnifyingglass")
        )
        configureNavigationBar(searchNav)

        // Notifications
        let notificationsVC = NotificationsViewController()
        let notificationsNav = UINavigationController(rootViewController: notificationsVC)
        notificationsNav.tabBarItem = UITabBarItem(
            title: "消息",
            image: UIImage(systemName: "bell"),
            selectedImage: UIImage(systemName: "bell.fill")
        )
        configureNavigationBar(notificationsNav)

        // Profile
        let profileVC = ProfileViewController()
        let profileNav = UINavigationController(rootViewController: profileVC)
        profileNav.tabBarItem = UITabBarItem(
            title: "我的",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )
        configureNavigationBar(profileNav)

        viewControllers = [homeNav, searchNav, notificationsNav, profileNav]
    }

    private func configureNavigationBar(_ navController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.card
        appearance.titleTextAttributes = [.foregroundColor: Theme.foreground]
        appearance.largeTitleTextAttributes = [.foregroundColor: Theme.foreground]
        appearance.shadowColor = .clear

        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        navController.navigationBar.compactAppearance = appearance
        navController.navigationBar.tintColor = Theme.primary
    }
}
