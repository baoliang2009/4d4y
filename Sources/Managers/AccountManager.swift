import Foundation
import UIKit

class AccountManager {
    static let shared = AccountManager()

    private let accountsKey = "accounts_list"
    private let currentAccountKey = "current_account_id"
    private let cookiesKeyPrefix = "cookies_"
    private let lastCheckKeyPrefix = "last_check_"

    private(set) var accounts: [Account] = []
    var currentAccountId: UUID?
    var currentAccount: Account? {
        guard let id = currentAccountId else { return nil }
        return accounts.first { $0.id == id }
    }

    private init() {
        loadAccounts()
    }

    // MARK: - Load/Save

    func loadAccounts() {
        guard let data = UserDefaults.standard.data(forKey: accountsKey),
              let savedAccounts = try? JSONDecoder().decode([Account].self, from: data) else {
            accounts = []
            return
        }
        accounts = savedAccounts

        if let currentIdString = UserDefaults.standard.string(forKey: currentAccountKey),
           let currentId = UUID(uuidString: currentIdString) {
            currentAccountId = currentId
        } else if let first = accounts.first {
            currentAccountId = first.id
        }

        // Restore cookies for current account if exists
        if let currentId = currentAccountId {
            loadCookies(for: currentId)
        }
    }

    func saveAccounts() {
        guard let data = try? JSONEncoder().encode(accounts) else { return }
        UserDefaults.standard.set(data, forKey: accountsKey)
    }

    func saveCurrentAccountId() {
        UserDefaults.standard.set(currentAccountId?.uuidString, forKey: currentAccountKey)
    }

    // MARK: - Account Operations

    func addAccount(username: String, password: String, questionId: Int, answer: String, uid: Int) throws -> Account {
        let account = Account(username: username, uid: uid, isCurrent: true)

        // Save credentials to keychain
        let credentials = AccountCredentials(
            accountId: account.id,
            username: username,
            password: password,
            questionId: questionId,
            answer: answer
        )
        guard KeychainHelper.shared.saveCredentials(credentials) else {
            throw AccountError.keychainSaveFailed
        }

        // Update accounts list
        for i in accounts.indices {
            accounts[i].isCurrent = false
        }
        accounts.append(account)
        saveAccounts()

        // Switch to new account
        switchAccount(id: account.id)

        return account
    }

    func removeAccount(id: UUID) {
        // Remove credentials from keychain
        KeychainHelper.shared.deleteCredentials(for: id)

        // Remove cookies
        UserDefaults.standard.removeObject(forKey: cookiesKeyPrefix + id.uuidString)

        // Remove from accounts list
        accounts.removeAll { $0.id == id }
        saveAccounts()

        // If removed was current, switch to another
        if currentAccountId == id {
            if let next = accounts.first {
                switchAccount(id: next.id)
            } else {
                currentAccountId = nil
                saveCurrentAccountId()
                clearCurrentSession()
            }
        }
    }

    func switchAccount(id: UUID) {
        guard let account = accounts.first(where: { $0.id == id }) else { return }

        // Save current cookies before switching
        if let currentId = currentAccountId {
            saveCookies(for: currentId)
        }

        // Update current account
        for i in accounts.indices {
            accounts[i].isCurrent = (accounts[i].id == id)
        }

        currentAccountId = id
        saveAccounts()
        saveCurrentAccountId()

        // Load cookies for new account
        loadCookies(for: id)

        // Update last used
        updateLastUsed(id: id)

        // Post notification
        NotificationCenter.default.post(name: .accountDidSwitch, object: nil)
    }

    func updateLastUsed(id: UUID) {
        guard let index = accounts.firstIndex(where: { $0.id == id }) else { return }
        accounts[index].lastUsedAt = Date()
        saveAccounts()
    }

    // MARK: - Credentials

    func getCredentials(for id: UUID) -> AccountCredentials? {
        return KeychainHelper.shared.loadCredentials(for: id)
    }

    // MARK: - Cookies

    func getCookies(for id: UUID) -> [HTTPCookie] {
        guard let data = UserDefaults.standard.data(forKey: cookiesKeyPrefix + id.uuidString) else {
            return []
        }

        // Deserialize cookies from data
        guard let cookies = NSKeyedUnarchiver.unarchiveObject(with: data) as? [HTTPCookie] else {
            return []
        }
        return cookies
    }

    func saveCookies(for id: UUID) {
        let cookies = HTTPCookieStorage.shared.cookies ?? []
        guard let data = try? NSKeyedArchiver.archivedData(withRootObject: cookies, requiringSecureCoding: false) else {
            return
        }
        UserDefaults.standard.set(data, forKey: cookiesKeyPrefix + id.uuidString)
    }

    func loadCookies(for id: UUID) {
        // Clear current cookies
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }

        // Load and set cookies for account
        let cookies = getCookies(for: id)
        for cookie in cookies {
            HTTPCookieStorage.shared.setCookie(cookie)
        }
    }

    // MARK: - Session

    func clearCurrentSession() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        NotificationCenter.default.post(name: .accountDidSwitch, object: nil)
    }

    // MARK: - Last Check Timestamp

    func getLastCheckTimestamp(for accountId: UUID) -> Date? {
        return UserDefaults.standard.object(forKey: lastCheckKeyPrefix + accountId.uuidString) as? Date
    }

    func saveLastCheckTimestamp(for accountId: UUID, date: Date) {
        UserDefaults.standard.set(date, forKey: lastCheckKeyPrefix + accountId.uuidString)
    }
}

// MARK: - Errors

enum AccountError: LocalizedError {
    case keychainSaveFailed
    case accountNotFound
    case loginFailed

    var errorDescription: String? {
        switch self {
        case .keychainSaveFailed: return "无法保存凭证到密钥库"
        case .accountNotFound: return "账号不存在"
        case .loginFailed: return "登录失败"
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let accountDidSwitch = Notification.Name("accountDidSwitch")
}
