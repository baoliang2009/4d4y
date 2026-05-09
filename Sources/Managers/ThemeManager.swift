import Foundation
import UIKit

enum ThemeType: String {
    case light
    case dark

    var displayName: String {
        switch self {
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }
}

class ThemeManager {
    static let shared = ThemeManager()

    private let themeKey = "app_theme_type"

    var currentTheme: ThemeType {
        get {
            guard let themeString = UserDefaults.standard.string(forKey: themeKey),
                  let theme = ThemeType(rawValue: themeString) else {
                return .dark // Default to dark
            }
            return theme
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: themeKey)
            applyTheme()
            NotificationCenter.default.post(name: .themeDidChange, object: newValue)
        }
    }

    private init() {}

    func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        if #available(iOS 15.0, *) {
            switch currentTheme {
            case .light:
                Theme.applyLightMode(to: window)
            case .dark:
                Theme.applyDarkMode(to: window)
            }
        }
    }
}
