import UIKit

enum Theme {
    // MARK: - Light Mode Colors
    static let lightBackground = UIColor(red: 0.941, green: 0.949, blue: 0.961, alpha: 1.0) // #F0F2F5
    static let lightForeground = UIColor(red: 0.102, green: 0.102, blue: 0.102, alpha: 1.0) // #1A1A1A
    static let lightCard = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0) // #FFFFFF
    static let lightSecondary = UIColor(red: 0.965, green: 0.965, blue: 0.976, alpha: 1.0) // #F6F6F8
    static let lightMuted = UIColor(red: 0.925, green: 0.925, blue: 0.941, alpha: 1.0) // #ECECF0
    static let lightBorder = UIColor(red: 0.898, green: 0.906, blue: 0.922, alpha: 1.0) // #E5E7EB
    static let lightSecondaryText = UIColor(red: 0.420, green: 0.451, blue: 0.502, alpha: 1.0) // #6B7280

    // MARK: - Dark Mode Colors
    // Deep space dark background - creates depth and atmosphere
    static let background = UIColor(red: 0.039, green: 0.039, blue: 0.059, alpha: 1.0) // #0A0A0F

    // Primary text - warm white for readability
    static let foreground = UIColor(red: 0.961, green: 0.961, blue: 0.969, alpha: 1.0) // #F5F5F7

    // Card surfaces - slightly elevated from background
    static let card = UIColor(red: 0.086, green: 0.086, blue: 0.114, alpha: 1.0) // #16161D

    // Primary accent - vibrant indigo for interactive elements
    static let primary = UIColor(red: 0.388, green: 0.4, blue: 0.945, alpha: 1.0) // #6366F1

    // Primary foreground for buttons
    static let primaryForeground = UIColor.white

    // Secondary surfaces - for nested content
    static let secondary = UIColor(red: 0.118, green: 0.118, blue: 0.157, alpha: 1.0) // #1E1E28

    // Muted elements - for disabled states and subtle UI
    static let muted = UIColor(red: 0.153, green: 0.153, blue: 0.184, alpha: 1.0) // #27272F

    // Subtle borders with transparency
    static let border = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08) // rgba(255, 255, 255, 0.08)

    // MARK: - Accent Colors for Visual Interest
    // Vibrant accent for highlights and important actions
    static let accent = UIColor(red: 0.467, green: 0.765, blue: 0.965, alpha: 1.0) // #78C3F6 - soft cyan blue

    // Success / positive states
    static let success = UIColor(red: 0.341, green: 0.780, blue: 0.537, alpha: 1.0) // #57C789 - fresh green

    // Warning states
    static let warning = UIColor(red: 0.992, green: 0.706, blue: 0.271, alpha: 1.0) // #FDB445 - warm amber

    // Hot thread indicator
    static let hot = UIColor(red: 0.996, green: 0.396, blue: 0.310, alpha: 1.0) // #FE6564 - vibrant coral

    // MARK: - Current Theme Colors
    static var currentBackground: UIColor {
        ThemeManager.shared.currentTheme == .light ? lightBackground : background
    }

    static var currentForeground: UIColor {
        ThemeManager.shared.currentTheme == .light ? lightForeground : foreground
    }

    static var currentCard: UIColor {
        ThemeManager.shared.currentTheme == .light ? lightCard : card
    }

    static var currentSecondary: UIColor {
        ThemeManager.shared.currentTheme == .light ? lightSecondary : secondary
    }

    static var currentMuted: UIColor {
        ThemeManager.shared.currentTheme == .light ? lightMuted : muted
    }

    static var currentBorder: UIColor {
        ThemeManager.shared.currentTheme == .light ? lightBorder : border
    }

    static var currentSecondaryText: UIColor {
        ThemeManager.shared.currentTheme == .light ? lightSecondaryText : secondaryText
    }

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

    // MARK: - Gradient Presets
    static var primaryGradient: CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.388, green: 0.4, blue: 0.945, alpha: 1.0).cgColor,
            UIColor(red: 0.267, green: 0.267, blue: 0.569, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        return gradient
    }

    static var accentGradient: CAGradientLayer {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.467, green: 0.765, blue: 0.965, alpha: 1.0).cgColor,
            UIColor(red: 0.388, green: 0.4, blue: 0.945, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        return gradient
    }

    // MARK: - Shadow Presets
    static func cardShadow() -> (color: CGColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        return (
            color: UIColor.black.cgColor,
            opacity: 0.3,
            offset: CGSize(width: 0, height: 4),
            radius: 12
        )
    }

    static func glowShadow(color: UIColor) -> (color: CGColor, opacity: Float, offset: CGSize, radius: CGFloat) {
        return (
            color: color.cgColor,
            opacity: 0.4,
            offset: CGSize(width: 0, height: 0),
            radius: 8
        )
    }

    // MARK: - Animation Durations
    static let fastAnimation: TimeInterval = 0.15
    static let normalAnimation: TimeInterval = 0.25
    static let slowAnimation: TimeInterval = 0.35

    // MARK: - Corner Radius
    static let smallRadius: CGFloat = 8
    static let mediumRadius: CGFloat = 12
    static let largeRadius: CGFloat = 16
    static let cardRadius: CGFloat = 16

    // MARK: - Spacing
    static let smallPadding: CGFloat = 8
    static let mediumPadding: CGFloat = 16
    static let largePadding: CGFloat = 24
    static let sectionPadding: CGFloat = 32

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

        // Add subtle gradient effect to navigation bar
        appearance.backgroundColor = UIColor(red: 0.086, green: 0.086, blue: 0.114, alpha: 0.95)

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = primary

        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(red: 0.086, green: 0.086, blue: 0.114, alpha: 0.95)
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

    // MARK: - Light Mode Appearance
    @available(iOS 15.0, *)
    static func applyLightMode(to window: UIWindow?) {
        guard let window = window else { return }

        // Configure global appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = lightCard
        appearance.titleTextAttributes = [.foregroundColor: lightForeground]
        appearance.largeTitleTextAttributes = [.foregroundColor: lightForeground]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = primary

        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = lightCard
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        UITabBar.appearance().tintColor = primary

        // Table view appearance
        UITableView.appearance().backgroundColor = lightBackground
        UITableView.appearance().separatorColor = lightBorder

        // Table cell appearance
        UITableViewCell.appearance().backgroundColor = .clear

        // Refresh control
        UIRefreshControl.appearance().tintColor = primary
    }

    // MARK: - Convenience Methods
    static func animated(_ duration: TimeInterval = normalAnimation, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, options: [.curveEaseOut], animations: animations, completion: completion)
    }

    static func springAnimation(duration: TimeInterval = normalAnimation, damping: CGFloat = 0.8, velocity: CGFloat = 0.5, animations: @escaping () -> Void, completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: damping, initialSpringVelocity: velocity, options: [.curveEaseOut], animations: animations, completion: completion)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let themeDidChange = Notification.Name("themeDidChange")
}