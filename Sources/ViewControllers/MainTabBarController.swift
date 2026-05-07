import UIKit

class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAppearance()
        setupViewControllers()
    }

    private func setupAppearance() {
        // Tab bar appearance with glass effect
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.currentCard.withAlphaComponent(0.98)

        // Add blur effect for depth
        appearance.backgroundEffect = UIBlurEffect(style: .systemMaterialDark)

        // Normal state - subtle and refined
        appearance.stackedLayoutAppearance.normal.iconColor = Theme.currentSecondaryText
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: Theme.currentSecondaryText,
            .font: UIFont.systemFont(ofSize: 11, weight: .medium)
        ]

        // Selected state - vibrant and prominent
        appearance.stackedLayoutAppearance.selected.iconColor = Theme.primary
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: Theme.primary,
            .font: UIFont.systemFont(ofSize: 11, weight: .semibold)
        ]

        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
        tabBar.tintColor = Theme.primary

        // Add subtle top border with gradient effect
        tabBar.layer.borderWidth = 0.5
        tabBar.layer.borderColor = Theme.currentBorder.cgColor
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
            image: UIImage(systemName: "sparkle.magnifyingglass"),
            selectedImage: UIImage(systemName: "sparkle.magnifyingglass")
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
            image: UIImage(systemName: "person.crop.circle"),
            selectedImage: UIImage(systemName: "person.crop.circle.fill")
        )
        configureNavigationBar(profileNav)

        viewControllers = [homeNav, searchNav, notificationsNav, profileNav]
    }

    private func configureNavigationBar(_ navController: UINavigationController) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.currentCard.withAlphaComponent(0.95)
        appearance.titleTextAttributes = [
            .foregroundColor: Theme.currentForeground,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: Theme.currentForeground,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
        appearance.shadowColor = .clear

        navController.navigationBar.standardAppearance = appearance
        navController.navigationBar.scrollEdgeAppearance = appearance
        navController.navigationBar.compactAppearance = appearance
        navController.navigationBar.tintColor = Theme.primary

        // Enable large titles
        navController.navigationBar.prefersLargeTitles = false
    }
}
