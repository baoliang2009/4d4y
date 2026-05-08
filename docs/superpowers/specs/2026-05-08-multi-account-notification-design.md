# Multi-Account + Background Notification System Design

## Overview

Add multi-account support and silent background notification checking to FourD4Y iOS app. No push server required — uses iOS background app refresh to periodically check for new replies and PMs.

---

## 1. Account Data Model

### Structures

```
Account {
    id: UUID
    username: String
    uid: Int
    createdAt: Date
    lastUsedAt: Date
    isCurrent: Bool
}

AccountCredentials {
    accountId: UUID  // Keychain item identifier
    username: String
    password: String  // Stored in Keychain
    questionId: Int
    answer: String    // Stored in Keychain
}

AccountCookies {
    accountId: UUID
    cookies: Data  // Serialized HTTPCookie array
}
```

### Storage Strategy

- **Accounts list**: `UserDefaults` (non-sensitive metadata)
- **Credentials (password, answer)**: iOS Keychain per account
- **Cookies**: Separate storage per account (UserDefaults or file)

---

## 2. AccountManager

### Interface

```
AccountManager {
    static let shared: AccountManager

    var accounts: [Account]
    var currentAccountId: UUID?
    var currentAccount: Account?

    func loadAccounts()
    func addAccount(username:String, password:String, questionId:Int, answer:String) async throws -> Account
    func removeAccount(id: UUID)
    func switchAccount(id: UUID)
    func updateLastUsed(id: UUID)
    func getCredentials(for id: UUID) -> AccountCredentials?
    func getCookies(for id: UUID) -> [HTTPCookie]
    func saveCookies(for id: UUID, cookies: [HTTPCookie])
    func clearCurrentSession()
}
```

### Switching Logic

When `switchAccount(id)` is called:
1. Save current cookies for old account
2. Clear URLSession cookies
3. Load cookies for new account into `HTTPCookieStorage.shared`
4. Update `currentAccountId`
5. Post `accountDidSwitch` notification
6. Refresh UI (reload MainTabBar, etc.)

---

## 3. Background Fetch Architecture

### Components

```
BackgroundTaskScheduler {
    func scheduleBackgroundFetch()
    func handleAppRefresh(task: BGAppRefreshTask)
}

NotificationChecker {
    func checkAllAccounts() async
    func checkReplies(for accountId: UUID) async -> [NotificationItem]
    func checkPMs(for accountId: UUID) async -> [NotificationItem]
    func getLastCheckTimestamp(for accountId: UUID) -> Date?
    func saveLastCheckTimestamp(for accountId: UUID, date: Date)
}

NotificationItem {
    let id: String
    let type: NotificationType  // .reply, .pm
    let threadId: Int?
    let postId: Int?
    let title: String
    let preview: String
    let date: Date
    let accountId: UUID
}
```

### Flow

```
1. iOS triggers BGAppRefreshTask (configured in Info.plist)
2. BackgroundTaskScheduler.handleAppRefresh() called
3. For each logged-in account:
   a. Get last check timestamp
   b. Call forum API (viewthread.php or pm.php) to check for newer items
   c. Compare with last timestamp
   d. If new items found → create UNMutableNotificationContent
   e. Schedule with UNUserNotificationCenter
4. Save new timestamp
5. Set task expiration handler
```

### Forum API Checks

- **Replies**: Fetch user's recent posts via `space.php?uid={uid}&do=posts` or similar
- **PMs**: Fetch PM list via `pm.php?folder=inbox`

---

## 4. UI Components

### 4.1 Account Switcher

**Entry Points:**
- Floating Action Button (FAB) — bottom-right corner on main screens
- Profile menu — tap avatar/username in navigation bar

**Sheet Presentation:**
```
AccountSwitcherViewController {
    presented as: .pageSheet (iOS 15+)

    header: "切换账号"
    tableView: [
        AccountRow (current account, with checkmark)
        AccountRow (other accounts)
        AccountRow (other accounts)
        ...
    ]
    footer: "添加新账号" button

    AccountRow {
        avatar: UIImageView (36x36, rounded)
        username: UILabel (bold if current)
        badge: "当前" label (green, if current)
        checkmark: UIImageView (if current)
    }
}
```

### 4.2 Add Account Flow

```
AddAccountViewController {
    navigation: UINavigationController

    form fields:
    - username: UITextField
    - password: UITextField (secure)
    - question: UIPicker (0=无, 1-5=预设安全问题)
    - answer: UITextField

    buttons:
    - "登录" (primary, disabled until fields valid)
    - "取消" (cancel)

    error handling: inline error label
}
```

### 4.3 Notifications Tab

**New dedicated tab in MainTabBarController:**

```
NotificationsViewController {
    tableView: UITableView (grouped style)

    sections: [
        "私信" (PMs, envelope icon)
        "回复" (Replies, bubble icon)
    ]

    empty state: "暂无通知"
    loading state: UIActivityIndicatorView
}

NotificationCell {
    icon: UIImageView (24x24, tinted)
    title: UILabel (bold, 1 line)
    preview: UILabel (secondary color, 2 lines)
    date: UILabel (right-aligned, secondary)
    unreadDot: UIView (8pt blue circle, hidden if read)
}
```

### 4.4 Notification Categories

```
UNNotificationCategory {
    name: "REPLY"
    actions: ["查看", "回复"]
}

UNNotificationCategory {
    name: "PM"
    actions: ["查看", "回复"]
}
```

Tap action opens:
- `ThreadDetailViewController` for replies
- `PMDetailViewController` for PMs

---

## 5. File Changes

### New Files

```
Sources/
├── Managers/
│   ├── AccountManager.swift       # Account CRUD + switching
│   └── NotificationChecker.swift # Background check logic
├── Models/
│   ├── Account.swift             # Account model
│   └── NotificationItem.swift    # Notification item model
├── ViewControllers/
│   ├── AccountSwitcherViewController.swift
│   ├── AddAccountViewController.swift
│   └── NotificationsViewController.swift
├── Views/
│   ├── AccountCell.swift
│   └── NotificationCell.swift
└── Services/
    └── BackgroundTaskService.swift
```

### Modified Files

```
Sources/
├── AppDelegate.swift           # Register background tasks, notification categories
├── LoginManager.swift          # Delegate to AccountManager
├── NetworkManager.swift       # Use current account's cookies
├── MainTabBarController.swift # Add Notifications tab
└── Info.plist                 # Add BGTaskSchedulerPermittedIdentifiers
```

---

## 6. Error Handling

| Scenario | Handling |
|----------|----------|
| Login failed | Show inline error in AddAccountViewController |
| Cookie expired | Auto-detect, prompt re-login for that account |
| Background fetch fails | Reschedule, no user-facing error |
| No network | Skip fetch, retry next interval |
| Account removed while in use | Clear session, switch to next available or show login |

---

## 7. Security Considerations

- Passwords stored in Keychain only (never UserDefaults)
- Cookies isolated per account (no cross-account leakage)
- Biometric unlock option for account switcher (future)
- Clear all data on account deletion

---

## 8. Dependencies

- `BGTaskScheduler` — built-in iOS background refresh
- `UserNotifications` — built-in local notifications
- `Security` framework — Keychain access (existing)
- No new third-party libraries needed
