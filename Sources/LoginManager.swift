import Foundation

class LoginManager {
    static let shared = LoginManager()

    private let usernameKey = "forum_username"
    private let passwordKey = "forum_password"
    private let questionIdKey = "forum_question_id"
    private let answerKey = "forum_answer"
    private let isLoggedInKey = "forum_is_logged_in"
    private let loginDateKey = "forum_login_date"
    private let cookiesKey = "forum_cookies"
    private let uidKey = "forum_uid"

    private init() {
        // Restore cookies on startup
        restoreCookies()
    }

    var username: String? {
        get { UserDefaults.standard.string(forKey: usernameKey) }
        set { UserDefaults.standard.set(newValue, forKey: usernameKey) }
    }

    var uid: Int {
        get { UserDefaults.standard.integer(forKey: uidKey) }
        set { UserDefaults.standard.set(newValue, forKey: uidKey) }
    }

    var password: String? {
        get { UserDefaults.standard.string(forKey: passwordKey) }
        set { UserDefaults.standard.set(newValue, forKey: passwordKey) }
    }

    var questionId: Int {
        get { UserDefaults.standard.integer(forKey: questionIdKey) }
        set { UserDefaults.standard.set(newValue, forKey: questionIdKey) }
    }

    var answer: String? {
        get { UserDefaults.standard.string(forKey: answerKey) }
        set { UserDefaults.standard.set(newValue, forKey: answerKey) }
    }

    var isLoggedIn: Bool {
        get {
            let loggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
            if loggedIn {
                refreshLoginState()
            }
            return loggedIn
        }
        set { UserDefaults.standard.set(newValue, forKey: isLoggedInKey) }
    }

    private var loginDate: Date? {
        get { UserDefaults.standard.object(forKey: loginDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: loginDateKey) }
    }

    func saveCredentials(username: String, password: String, questionId: Int, answer: String, uid: Int = 0) {
        self.username = username
        self.password = password
        self.questionId = questionId
        self.answer = answer
        self.uid = uid
        self.loginDate = Date()
    }

    func clearCredentials() {
        username = nil
        password = nil
        questionId = 0
        answer = nil
        uid = 0
        isLoggedIn = false
        loginDate = nil
        clearCookies()
    }

    private func refreshLoginState() {
        guard let date = loginDate else {
            isLoggedIn = false
            return
        }
        let interval = Date().timeIntervalSince(date)
        if interval > 7 * 24 * 60 * 60 {
            isLoggedIn = false
        }
    }

    // MARK: - Cookie Persistence

    /// Save current cookies to UserDefaults
    func saveCookies() {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return }

        let cookieData = cookies.map { cookie in
            [
                "name": cookie.name,
                "value": cookie.value,
                "domain": cookie.domain,
                "path": cookie.path,
                "secure": cookie.isSecure
            ] as [String: Any]
        }

        UserDefaults.standard.set(cookieData, forKey: cookiesKey)
        print("[LoginManager] Saved \(cookies.count) cookies")
    }

    /// Restore cookies from UserDefaults
    func restoreCookies() {
        guard let cookieData = UserDefaults.standard.array(forKey: cookiesKey) as? [[String: Any]] else {
            return
        }

        let storage = HTTPCookieStorage.shared

        for data in cookieData {
            guard let name = data["name"] as? String,
                  let value = data["value"] as? String,
                  let domain = data["domain"] as? String,
                  let path = data["path"] as? String else {
                continue
            }

            let properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: domain,
                .path: path,
                .secure: data["secure"] as? Bool ?? false
            ]

            if let cookie = HTTPCookie(properties: properties) {
                storage.setCookie(cookie)
            }
        }

        if let cookies = storage.cookies {
            print("[LoginManager] Restored \(cookies.count) cookies")
        }
    }

    /// Clear saved cookies
    func clearCookies() {
        if let cookies = HTTPCookieStorage.shared.cookies {
            for cookie in cookies {
                HTTPCookieStorage.shared.deleteCookie(cookie)
            }
        }
        UserDefaults.standard.removeObject(forKey: cookiesKey)
    }

    /// Check if cookies exist and are valid
    func hasValidCookies() -> Bool {
        guard let cookies = HTTPCookieStorage.shared.cookies else { return false }

        let hasAuth = cookies.contains { $0.name == "cdb_auth" }
        let hasSid = cookies.contains { $0.name == "cdb_sid" }

        return hasAuth && hasSid
    }
    
    func getLoginJavaScript() -> String? {
        guard let username = username,
              let password = password else {
            return nil
        }
        
        let questionId = self.questionId
        let answer = self.answer ?? ""
        
        return """
        (function() {
            try {
                var form = document.getElementById('loginform');
                if (!form) return {success: false, error: 'no_form'};
                
                var usernameField = form.querySelector('input[name="username"]');
                var passwordField = document.getElementById('password3');
                var questionSelect = document.getElementById('questionid');
                var answerField = document.getElementById('answer');
                var cookietime = document.getElementById('cookietime');
                
                if (usernameField) usernameField.value = '\(username.escapedForJavaScript)';
                if (passwordField) passwordField.value = '\(password.escapedForJavaScript)';
                if (questionSelect) questionSelect.value = '\(questionId)';
                if (answerField) answerField.value = '\(answer.escapedForJavaScript)';
                if (cookietime) cookietime.checked = true;
                
                if (typeof hex_md5 === 'function' && passwordField) {
                    passwordField.value = hex_md5(passwordField.value);
                }
                
                return {success: true, needsMD5: typeof hex_md5 !== 'function'};
            } catch(e) {
                console.error('Login fill error:', e);
                return {success: false, error: e.message};
            }
        })();
        """
    }
    
    func getSubmitLoginJavaScript() -> String {
        return """
        (function() {
            try {
                var form = document.getElementById('loginform');
                if (!form) return {status: 'no_form'};
                
                var passwordField = document.getElementById('password3');
                if (passwordField && passwordField.value && passwordField.value.length !== 32) {
                    if (typeof hex_md5 === 'function') {
                        passwordField.value = hex_md5(passwordField.value);
                    }
                }
                
                form.submit();
                return {status: 'submitted'};
            } catch(e) {
                return {status: 'error', message: e.message};
            }
        })();
        """
    }
    
    func getCheckLoginStatusJavaScript() -> String {
        return """
        (function() {
            try {
                var umenu = document.getElementById('umenu');
                if (!umenu) return {loggedIn: false, reason: 'no_umenu'};
                
                var loginLink = umenu.querySelector('a[href*="login"]');
                var registerLink = umenu.querySelector('a[href*="tobenew"]');
                var usernameLinks = umenu.querySelectorAll('a[href*="space"]');
                var usernameLink = null;
                
                for (var i = 0; i < usernameLinks.length; i++) {
                    if (usernameLinks[i].textContent.trim().length > 0) {
                        usernameLink = usernameLinks[i];
                        break;
                    }
                }
                
                var discuzUid = typeof discuz_uid !== 'undefined' ? discuz_uid : 0;
                
                return {
                    loggedIn: !!usernameLink && !loginLink && discuzUid > 0,
                    username: usernameLink ? usernameLink.textContent.trim() : null,
                    discuzUid: discuzUid,
                    hasLoginLink: !!loginLink
                };
            } catch(e) {
                return {loggedIn: false, error: e.message};
            }
        })();
        """
    }
    
    func getLogoutJavaScript() -> String {
        return """
        (function() {
            try {
                var logoutLinks = document.querySelectorAll('a[href*="logging.php?action=logout"], a[href*="member.php?action=loggingout"]');
                if (logoutLinks.length > 0) {
                    window.location.href = logoutLinks[0].href;
                    return {status: 'redirecting'};
                }

                var xhr = new XMLHttpRequest();
                xhr.open('GET', 'logging.php?action=logout&formhash=' + (typeof formhash !== 'undefined' ? formhash : ''), false);
                xhr.send();

                return {status: 'done', redirect: xhr.responseURL};
            } catch(e) {
                return {status: 'error', message: e.message};
            }
        })();
        """
    }

    // MARK: - Native Login

    func loginWithNetwork() async throws -> Bool {
        guard let username = username,
              let password = password else {
            return false
        }

        return try await NetworkManager.shared.login(
            username: username,
            password: password,
            questionId: questionId,
            answer: answer ?? ""
        )
    }
}

extension String {
    var escapedForJavaScript: String {
        return self.replacingOccurrences(of: "\\", with: "\\\\")
                   .replacingOccurrences(of: "'", with: "\\'")
                   .replacingOccurrences(of: "\n", with: "\\n")
                   .replacingOccurrences(of: "\r", with: "\\r")
    }

    var jsEscaped: String {
        return self.escapedForJavaScript
    }
}
