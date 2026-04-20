import UIKit

enum Theme {
    // MARK: - Dark Mode Colors
    static let background = UIColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1.0) // #0A0A0F
    static let foreground = UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0) // #F5F5F7
    static let card = UIColor(red: 0.086, green: 0.086, blue: 0.114, alpha: 1.0) // #16161D
    static let primary = UIColor(red: 0.388, green: 0.4, blue: 0.945, alpha: 1.0) // #6366F1
    static let primaryForeground = UIColor.white
    static let secondary = UIColor(red: 0.118, green: 0.118, blue: 0.157, alpha: 1.0) // #1E1E28
    static let muted = UIColor(red: 0.153, green: 0.153, blue: 0.184, alpha: 1.0) // #27272F
    static let border = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08) // rgba(255, 255, 255, 0.08)

    // MARK: - Semantic Colors
    static let cardBackground = card
    static let cellBackground = card
    static let tableBackground = background
    static let separator = border

    // MARK: - Text Colors
    static let titleText = foreground
    static let bodyText = foreground
    static let secondaryText = UIColor(red: 0.6, green: 0.6, blue: 0.65, alpha: 1.0) // muted foreground
    static let linkText = primary

    // MARK: - Tint Color
    static let tint = primary

    // MARK: - Apply Theme
    @available(iOS 15.0, *)
    static func applyDarkMode(to window: UIWindow?) {
        guard let window = window else { return }

        // Configure global appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = card
        appearance.titleTextAttributes = [.foregroundColor: foreground]
        appearance.largeTitleTextAttributes = [.foregroundColor: foreground]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = primary

        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = card
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        UITabBar.appearance().tintColor = primary

        // Table view appearance
        UITableView.appearance().backgroundColor = background
        UITableView.appearance().separatorColor = border

        // Table cell appearance
        UITableViewCell.appearance().backgroundColor = .clear

        // Refresh control
        UIRefreshControl.appearance().tintColor = primary
    }
}
