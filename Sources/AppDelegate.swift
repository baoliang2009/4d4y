import UIKit
import SDWebImage
import WebKit
import BackgroundTasks
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// Hidden WKWebView to pre-load forum pages and initialize cookies
    /// This solves the issue where the first request to fetch forum list fails
    /// because the required cookies (like discuz_7e5) haven't been set yet.
    private var cookiePreloadWebView: WKWebView?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Configure SDWebImage for optimal image loading
        ImageLoader.configure()

        // Apply dark mode theme
        if #available(iOS 15.0, *) {
            Theme.applyDarkMode(to: nil)
        }

        // Pre-load forum page to initialize cookies before first network request
        preloadForumCookies()

        // Register background tasks
        BackgroundTaskService.shared.registerBackgroundTasks()

        // Register notification categories
        BackgroundTaskService.shared.registerNotificationCategories()

        // Request notification permission
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("[AppDelegate] Notification permission granted")
            }
        }

        return true
    }

    /// Pre-loads a lightweight forum page to initialize cookies in HTTPCookieStorage.shared
    /// This ensures that subsequent URLSession requests will include the required cookies
    private func preloadForumCookies() {
        print("[AppDelegate] Starting cookie pre-load...")

        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 1, height: 1), configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36"
        webView.isHidden = true
        webView.tag = 999  // Tag for identification

        // Store reference to prevent deallocation
        self.cookiePreloadWebView = webView

        // Use a simple lightweight page - memcp.php is good because:
        // 1. It's small (just user center header)
        // 2. It requires session cookies, so loading it ensures cookies are set
        // 3. It doesn't require JavaScript rendering for cookie setup
        let urlString = "https://www.4d4y.com/forum/memcp.php"

        guard let url = URL(string: urlString) else {
            print("[AppDelegate] Invalid pre-load URL")
            return
        }

        print("[AppDelegate] Loading URL for cookie init: \(urlString)")
        webView.load(URLRequest(url: url))
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}