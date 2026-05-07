import UIKit
import WebKit

protocol LoginViewControllerDelegate: AnyObject {
    func loginViewControllerDidLogin(_ controller: LoginViewController)
    func loginViewControllerDidLoginWithForumData(_ controller: LoginViewController, forums: [Forum])
    func loginViewControllerDidCancel(_ controller: LoginViewController)
}

// MARK: - LoginViewController

class LoginViewController: UIViewController {

    weak var delegate: LoginViewControllerDelegate?

    private let scrollView = UIScrollView()
    private let contentView = UIView()

    private let usernameTextField = UITextField()
    private let passwordTextField = UITextField()
    private let questionButton = UIButton(type: .system)
    private let answerTextField = UITextField()
    private let rememberMeSwitch = UISwitch()
    private let loginButton = UIButton(type: .system)

    private var selectedQuestionId = 0
    private let loginQuestions = [
        (id: 0, question: "安全提示问题"),
        (id: 1, question: "父亲出生的城市"),
        (id: 2, question: "母亲出生的城市"),
        (id: 3, question: "父亲工作的城市"),
        (id: 4, question: "心中最想念的地方"),
        (id: 5, question: "最爱的人的名字"),
        (id: 6, question: "最喜欢的食物"),
        (id: 7, question: "就读的第一所学校的名称")
    ]

    // MARK: - Loading Overlay

    private let loadingOverlay = UIView()
    private let loadingContainer = UIView()
    private let loadingSpinner = UIActivityIndicatorView(style: .large)
    private let loadingLabel = UILabel()
    private let loadingCancelButton = UIButton(type: .system)

    // MARK: - Login State

    private var webView: WKWebView?
    private var loginCompletion: ((Bool, String?) -> Void)?
    private var formhash: String?
    private var storedUsername: String = ""
    private var storedPassword: String = ""
    private var storedQuestionId: Int = 0
    private var storedAnswer: String = ""
    private var isLoggingIn = false
    private var loginStartTime: Date?

    // Timeout duration (60 seconds - increased for slow connections)
    private let loginTimeout: TimeInterval = 60

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLoadingOverlay()
        loadSavedCredentials()
    }

    private func setupUI() {
        title = "登录"
        view.backgroundColor = Theme.currentBackground

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.leftBarButtonItem?.tintColor = Theme.primary

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        setupUsernameField()
        setupPasswordField()
        setupQuestionField()
        setupAnswerField()
        setupRememberMe()
        setupLoginButton()
    }

    private func setupLoadingOverlay() {
        loadingOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        loadingOverlay.isHidden = true

        loadingContainer.backgroundColor = Theme.currentCard
        loadingContainer.layer.cornerRadius = 16
        loadingContainer.layer.borderColor = Theme.currentBorder.cgColor
        loadingContainer.layer.borderWidth = 1

        loadingSpinner.color = Theme.primary

        loadingLabel.text = "正在连接服务器..."
        loadingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        loadingLabel.textColor = Theme.currentForeground
        loadingLabel.textAlignment = .center
        loadingLabel.numberOfLines = 0

        loadingCancelButton.setTitle("取消", for: .normal)
        loadingCancelButton.setTitleColor(Theme.primary, for: .normal)
        loadingCancelButton.titleLabel?.font = .systemFont(ofSize: 15)
        loadingCancelButton.addTarget(self, action: #selector(cancelLoginTapped), for: .touchUpInside)

        view.addSubview(loadingOverlay)
        loadingOverlay.addSubview(loadingContainer)
        loadingContainer.addSubview(loadingSpinner)
        loadingContainer.addSubview(loadingLabel)
        loadingContainer.addSubview(loadingCancelButton)

        loadingOverlay.translatesAutoresizingMaskIntoConstraints = false
        loadingContainer.translatesAutoresizingMaskIntoConstraints = false
        loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
        loadingLabel.translatesAutoresizingMaskIntoConstraints = false
        loadingCancelButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loadingOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            loadingOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingContainer.centerXAnchor.constraint(equalTo: loadingOverlay.centerXAnchor),
            loadingContainer.centerYAnchor.constraint(equalTo: loadingOverlay.centerYAnchor),
            loadingContainer.widthAnchor.constraint(equalToConstant: 240),

            loadingSpinner.topAnchor.constraint(equalTo: loadingContainer.topAnchor, constant: 30),
            loadingSpinner.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),

            loadingLabel.topAnchor.constraint(equalTo: loadingSpinner.bottomAnchor, constant: 20),
            loadingLabel.leadingAnchor.constraint(equalTo: loadingContainer.leadingAnchor, constant: 20),
            loadingLabel.trailingAnchor.constraint(equalTo: loadingContainer.trailingAnchor, constant: -20),

            loadingCancelButton.topAnchor.constraint(equalTo: loadingLabel.bottomAnchor, constant: 20),
            loadingCancelButton.centerXAnchor.constraint(equalTo: loadingContainer.centerXAnchor),
            loadingCancelButton.bottomAnchor.constraint(equalTo: loadingContainer.bottomAnchor, constant: -20)
        ])
    }

    private func showLoading(message: String) {
        loadingLabel.text = message
        loadingSpinner.startAnimating()
        loadingOverlay.isHidden = false
        loginButton.isEnabled = false
    }

    private func updateLoadingMessage(_ message: String) {
        loadingLabel.text = message
    }

    private func hideLoading() {
        loadingOverlay.isHidden = true
        loadingSpinner.stopAnimating()
        loginButton.isEnabled = true
    }

    private func setupUsernameField() {
        let label = UILabel()
        label.text = "用户名"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.currentSecondaryText

        usernameTextField.borderStyle = .roundedRect
        usernameTextField.autocapitalizationType = .none
        usernameTextField.autocorrectionType = .no
        usernameTextField.placeholder = "输入用户名"
        usernameTextField.backgroundColor = Theme.currentMuted
        usernameTextField.textColor = Theme.currentForeground

        contentView.addSubview(label)
        contentView.addSubview(usernameTextField)

        label.translatesAutoresizingMaskIntoConstraints = false
        usernameTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            usernameTextField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            usernameTextField.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            usernameTextField.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            usernameTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupPasswordField() {
        let label = UILabel()
        label.text = "密码"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.currentSecondaryText

        passwordTextField.borderStyle = .roundedRect
        passwordTextField.isSecureTextEntry = true
        passwordTextField.placeholder = "输入密码"
        passwordTextField.backgroundColor = Theme.currentMuted
        passwordTextField.textColor = Theme.currentForeground

        contentView.addSubview(label)
        contentView.addSubview(passwordTextField)

        label.translatesAutoresizingMaskIntoConstraints = false
        passwordTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: usernameTextField.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            passwordTextField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            passwordTextField.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            passwordTextField.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            passwordTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupQuestionField() {
        let label = UILabel()
        label.text = "安全问题"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.currentSecondaryText

        questionButton.setTitle(loginQuestions[0].question, for: .normal)
        questionButton.contentHorizontalAlignment = .left
        questionButton.titleLabel?.font = .systemFont(ofSize: 16)
        questionButton.tintColor = Theme.currentForeground
        questionButton.layer.borderWidth = 1
        questionButton.layer.borderColor = Theme.currentBorder.cgColor
        questionButton.layer.cornerRadius = 5
        questionButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        questionButton.addTarget(self, action: #selector(selectQuestion), for: .touchUpInside)

        contentView.addSubview(label)
        contentView.addSubview(questionButton)

        label.translatesAutoresizingMaskIntoConstraints = false
        questionButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: passwordTextField.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            questionButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            questionButton.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            questionButton.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            questionButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupAnswerField() {
        let label = UILabel()
        label.text = "安全问题答案"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.currentSecondaryText

        answerTextField.borderStyle = .roundedRect
        answerTextField.placeholder = "输入答案"
        answerTextField.autocapitalizationType = .none
        answerTextField.autocorrectionType = .no
        answerTextField.backgroundColor = Theme.currentMuted
        answerTextField.textColor = Theme.currentForeground

        contentView.addSubview(label)
        contentView.addSubview(answerTextField)

        label.translatesAutoresizingMaskIntoConstraints = false
        answerTextField.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: questionButton.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

            answerTextField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            answerTextField.leadingAnchor.constraint(equalTo: label.leadingAnchor),
            answerTextField.trailingAnchor.constraint(equalTo: label.trailingAnchor),
            answerTextField.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func setupRememberMe() {
        let label = UILabel()
        label.text = "记住登录"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.currentSecondaryText

        rememberMeSwitch.isOn = true
        rememberMeSwitch.onTintColor = Theme.primary

        contentView.addSubview(label)
        contentView.addSubview(rememberMeSwitch)

        label.translatesAutoresizingMaskIntoConstraints = false
        rememberMeSwitch.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: answerTextField.bottomAnchor, constant: 20),
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),

            rememberMeSwitch.centerYAnchor.constraint(equalTo: label.centerYAnchor),
            rememberMeSwitch.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }

    private func setupLoginButton() {
        loginButton.setTitle("登录", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        loginButton.backgroundColor = Theme.primary
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        contentView.addSubview(loginButton)

        loginButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            loginButton.topAnchor.constraint(equalTo: rememberMeSwitch.bottomAnchor, constant: 30),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            loginButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func loadSavedCredentials() {
        if let username = LoginManager.shared.username {
            usernameTextField.text = username
        }
        if let password = LoginManager.shared.password {
            passwordTextField.text = password
        }
        selectedQuestionId = LoginManager.shared.questionId
        questionButton.setTitle(loginQuestions.first { $0.id == selectedQuestionId }?.question ?? "安全提示问题", for: .normal)
        answerTextField.text = LoginManager.shared.answer
    }

    @objc private func cancelTapped() {
        delegate?.loginViewControllerDidCancel(self)
        dismiss(animated: true)
    }

    @objc private func cancelLoginTapped() {
        cancelLogin()
        hideLoading()
        loginButton.setTitle("登录", for: .normal)
    }

    @objc private func selectQuestion() {
        let alert = UIAlertController(title: "选择安全问题", message: nil, preferredStyle: .actionSheet)

        for question in loginQuestions {
            alert.addAction(UIAlertAction(title: question.question, style: .default) { [weak self] _ in
                self?.selectedQuestionId = question.id
                self?.questionButton.setTitle(question.question, for: .normal)
            })
        }

        alert.addAction(UIAlertAction(title: "取消", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = questionButton
            popover.sourceRect = questionButton.bounds
        }

        present(alert, animated: true)
    }

    @objc private func loginTapped() {
        guard let username = usernameTextField.text, !username.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "错误", message: "请输入用户名和密码")
            return
        }

        let answer = answerTextField.text ?? ""

        loginButton.isEnabled = false
        loginButton.setTitle("登录中...", for: .normal)

        // Show loading overlay with status
        showLoading(message: "正在连接服务器...")

        // Use WKWebView-based login to handle Cloudflare
        loginWithWebView(
            username: username,
            password: password,
            questionId: selectedQuestionId,
            answer: answer
        ) { [weak self] success, errorMessage in
            DispatchQueue.main.async {
                guard let self = self else { return }

                self.hideLoading()
                self.loginButton.isEnabled = true
                self.loginButton.setTitle("登录", for: .normal)

                if success {
                    if self.rememberMeSwitch.isOn {
                        LoginManager.shared.saveCredentials(
                            username: username,
                            password: password,
                            questionId: self.selectedQuestionId,
                            answer: answer
                        )
                    }
                    LoginManager.shared.isLoggedIn = true

                    // Clear forum list cache so it refreshes with logged-in data
                    CacheManager.shared.clearCache(forKey: CacheManager.CacheKeys.forumList())
                    print("[Login] Cleared forum list cache after successful login")

                    self.delegate?.loginViewControllerDidLogin(self)
                    self.dismiss(animated: true)
                } else {
                    self.showAlert(title: "登录失败", message: errorMessage ?? "登录失败")
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Cancel Login

    private var loginTimeoutTimer: Timer?

    private func cancelLogin() {
        loginTimeoutTimer?.invalidate()
        loginTimeoutTimer = nil
        isLoggingIn = false

        // Cancel any pending webview loads
        webView?.stopLoading()
        webView?.removeFromSuperview()
        webView = nil
    }

    private func startLoginTimeoutTimer() {
        loginTimeoutTimer?.invalidate()
        loginTimeoutTimer = Timer.scheduledTimer(withTimeInterval: loginTimeout, repeats: false) { [weak self] _ in
            self?.handleLoginTimeout()
        }
    }

    private func handleLoginTimeout() {
        print("[Login] Login timeout after \(loginTimeout) seconds")
        cancelLogin()

        DispatchQueue.main.async { [weak self] in
            self?.hideLoading()
            self?.loginButton.isEnabled = true
            self?.loginButton.setTitle("登录", for: .normal)
            self?.showAlert(title: "登录超时", message: "连接服务器超时，请检查网络后重试")
        }
    }

    // MARK: - WKWebView Login

    private var forumListCompletion: (([Forum]) -> Void)?
    private var webViewLoadStartTime: Date?

    private func loginWithWebView(
        username: String,
        password: String,
        questionId: Int,
        answer: String,
        completion: @escaping (Bool, String?) -> Void
    ) {
        self.loginCompletion = completion
        self.storedUsername = username
        self.storedPassword = password
        self.storedQuestionId = questionId
        self.storedAnswer = answer
        self.loginStartTime = Date()
        self.isLoggingIn = true

        // Create visible WebView for better stability on real devices
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()

        let webView = WKWebView(frame: view.bounds, configuration: configuration)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36"
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.frame = view.bounds
        webView.isHidden = true  // Keep hidden but full size
        self.webView = webView
        self.webViewLoadStartTime = Date()
        view.addSubview(webView)

        // Store for later use
        self.formhash = nil

        // Start timeout timer
        startLoginTimeoutTimer()

        // Set forumListCompletion before performLogin so it's ready when we redirect to index.php
        self.forumListCompletion = { _ in }

        // Load login page to get formhash
        updateLoadingMessage("正在加载登录页面...")
        let loginURL = URL(string: "https://www.4d4y.com/forum/logging.php?action=login")!
        webView.load(URLRequest(url: loginURL))

        print("[Login] Loading login page via WKWebView...")
    }

    private func performLogin() {
        guard let webView = webView, let formhash = self.formhash else {
            print("[Login] Cannot perform login: webView=\(webView != nil), formhash=\(self.formhash ?? "nil")")
            loginCompletion?(false, "无法获取表单hash")
            return
        }

        let username = storedUsername
        let password = storedPassword
        let questionId = storedQuestionId
        let answer = storedAnswer
        let passwordMD5 = password.md5

        print("[Login] Performing login with formhash: \(formhash)")

        updateLoadingMessage("正在验证用户信息...")

        // JavaScript to submit login form via AJAX
        let js = #"""
        (function() {
            var xhr = new XMLHttpRequest();
            xhr.open('POST', 'https://www.4d4y.com/forum/logging.php?action=login&loginsubmit=yes&inajax=1', true);
            xhr.setRequestHeader('Content-Type', 'application/x-www-form-urlencoded');
            xhr.setRequestHeader('Origin', 'https://www.4d4y.com');
            xhr.setRequestHeader('Referer', 'https://www.4d4y.com/forum/logging.php?action=login');
            xhr.withCredentials = true;
            xhr.onload = function() {
                console.log('Login XHR completed, status:', xhr.status, 'responseURL:', xhr.responseURL);
                var response = xhr.responseText ? xhr.responseText.substring(0, 1000) : 'empty';
                console.log('Login XHR response:', response);
                // Check if login succeeded - Discuz returns specific patterns
                var loginSuccess = response.includes('succeedhandle') ||
                                   response.includes('登录成功') ||
                                   response.includes('location.href') ||
                                   (xhr.status >= 200 && xhr.status < 300);
                console.log('Login success check:', loginSuccess);
                window.location.href = 'https://www.4d4y.com/forum/';
            };
            xhr.onerror = function() {
                console.log('Login XHR error, status:', xhr.status);
                window.location.href = 'https://www.4d4y.com/forum/';
            };
            xhr.onloadstart = function() {
                console.log('Login XHR started');
            };
            xhr.ontimeout = function() {
                console.log('Login XHR timeout');
            };
            var params = 'formhash=' + encodeURIComponent('\#(formhash)') +
                '&referer=' + encodeURIComponent('https%3A%2F%2Fwww.4d4y.com%2Fforum%2F') +
                '&loginfield=username' +
                '&username=' + encodeURIComponent('\#(username)') +
                '&password=' + encodeURIComponent('\#(passwordMD5)') +
                '&questionid=' + encodeURIComponent('\#(questionId)') +
                '&answer=' + encodeURIComponent('\#(answer)') +
                '&cookietime=2592000';
            console.log('Sending login request with params:', params);
            xhr.send(params);
        })();
        """#

        webView.evaluateJavaScript(js) { [weak self] result, error in
            if let error = error {
                print("[Login] JS error: \(error.localizedDescription)")
            }
            print("[Login] Login JS executed")
        }
    }

    private func syncCookiesToSharedStorage(from webView: WKWebView, completion: @escaping (Bool) -> Void) {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            print("[CookieSync] WKWebView cookies count: \(cookies.count)")
            for cookie in cookies {
                print("[CookieSync] WKCookie: \(cookie.name)=\(cookie.value.prefix(30))... domain=\(cookie.domain) path=\(cookie.path)")
            }

            let storage = HTTPCookieStorage.shared
            for cookie in cookies {
                // Only sync cookies for 4d4y.com domain
                if cookie.domain.contains("4d4y.com") {
                    if let existingCookie = storage.cookies?.first(where: { $0.name == cookie.name }) {
                        storage.deleteCookie(existingCookie)
                    }
                    storage.setCookie(cookie)
                    print("[CookieSync] Synced: \(cookie.name) = \(cookie.value.prefix(20))...")
                }
            }
            print("[CookieSync] Total cookies synced to shared: \(cookies.count)")

            // Check for required login cookies in the original cookies
            let hasAuth = cookies.contains { $0.name == "cdb_auth" }
            let hasSid = cookies.contains { $0.name == "cdb_sid" }
            print("[CookieSync] Has cdb_auth: \(hasAuth), Has cdb_sid: \(hasSid)")

            // Now also save cookies to LoginManager for persistence
            LoginManager.shared.saveCookies()

            completion(hasAuth && hasSid)
        }
    }

    /// Parse forum list HTML to extract Forum objects
    private func parseForumListHTML(_ html: String) -> [Forum]? {
        var forums: [Forum] = []

        // Pattern to match forum links with fid
        let pattern = "href=\"[^\"]*?fid=(\\d+)[^\"]*?\"[^>]*?>([^<]+)</a>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            if let fidRange = Range(match.range(at: 1), in: html),
               let nameRange = Range(match.range(at: 2), in: html),
               let fid = Int(html[fidRange]) {
                let name = String(html[nameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty && name.count < 100 {
                    let forum = Forum(fid: fid, name: name, description: "", threadCount: 0, postCount: 0)
                    forums.append(forum)
                }
            }
        }

        // Remove duplicates by fid
        var uniqueForums: [Forum] = []
        var seenFids = Set<Int>()
        for forum in forums {
            if !seenFids.contains(forum.fid) {
                seenFids.insert(forum.fid)
                uniqueForums.append(forum)
            }
        }

        return uniqueForums
    }

    private func cleanup() {
        loginTimeoutTimer?.invalidate()
        loginTimeoutTimer = nil
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.webView?.isHidden = true
            self?.webView?.removeFromSuperview()
            self?.webView = nil
        }
    }
}

// MARK: - WKNavigationDelegate

extension LoginViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        let urlString = webView.url?.absoluteString ?? ""
        let elapsed = Date().timeIntervalSince(loginStartTime ?? Date())
        print("[Login] Page loaded [\(String(format: "%.1f", elapsed))s]: \(urlString)")

        // Check if this is the memcp.php page (for UID extraction)
        if urlString.contains("memcp.php") {
            print("[Login] Detected memcp.php page, extracting UID...")
            updateLoadingMessage("正在获取用户信息...")
            extractUIDFromMemcp(webView: webView)
            return
        }

        // Check if this is the forum index page (being loaded after login success)
        // Handle both forum/index.php and forum/ (base URL after redirect)
        if urlString.contains("forum/index.php") || (urlString.contains("4d4y.com/forum/") && !urlString.contains("logging.php") && !urlString.contains("post.php")) {
            print("[Login] Detected forum page after login, syncing cookies...")
            print("[Login] URL: \(urlString)")
            updateLoadingMessage("正在同步登录状态...")
            // Sync cookies before extracting forum list or completing login
            syncCookiesToSharedStorage(from: webView) { [weak self] hasCookies in
                guard let self = self else { return }
                print("[Login] Cookie sync result: hasCookies=\(hasCookies)")

                if hasCookies {
                    // Now proceed to memcp.php to get UID
                    print("[Login] Proceeding to memcp.php to get UID...")
                    self.updateLoadingMessage("正在获取用户信息...")
                    let memcpURL = URL(string: "https://www.4d4y.com/forum/memcp.php")!
                    webView.load(URLRequest(url: memcpURL))
                } else {
                    // No cookies, login might have failed
                    print("[Login] No auth cookies, login may have failed")
                    self.loginCompletion?(false, "登录失败，未获取到有效的会话")
                    self.cleanup()
                }
            }
            return
        }

        // Only check for logged in status on the login page itself
        if urlString.contains("logging.php") && !isLoggingIn {
            print("[Login] On login page, checking status...")

            // First check if already logged in
            webView.evaluateJavaScript("document.body.innerText") { [weak self] result, error in
                guard let self = self else { return }

                if let error = error {
                    print("[Login] Error getting body text: \(error.localizedDescription)")
                }

                if let text = result as? String {
                    print("[Login] Body text preview: \(String(text.prefix(100)))")
                    if text.contains("欢迎") || text.contains("vkeypm") || text.contains("个人中心") || text.contains("登录") && text.contains("密码") {
                        print("[Login] User already logged in or on login page, checking for form...")
                        self.handleLoginSuccess(webView: webView)
                        return
                    }
                }

                // Not logged in, try to extract formhash
                print("[Login] Not logged in, extracting formhash...")
                self.extractFormhashAndLogin(webView: webView)
            }
        } else if urlString.contains("logging.php") && isLoggingIn {
            print("[Login] On login page with isLoggingIn=true, checking if form exists...")
            // Check if login form exists - if not, user is already logged in
            webView.evaluateJavaScript("document.querySelector('form[name=login]') || document.querySelector('#loginform') ? 'has_form' : 'no_form'") { [weak self] result, _ in
                guard let self = self else { return }

                let hasForm = result as? String == "has_form"
                print("[Login] Login form exists: \(hasForm)")

                if hasForm {
                    // Form exists, try to extract formhash
                    self.extractFormhashAndLogin(webView: webView)
                } else {
                    // No form means user is already logged in
                    print("[Login] No login form found, user is already logged in")
                    self.isLoggingIn = false // Reset state
                    self.handleLoginSuccess(webView: webView)
                }
            }
        }
    }

    private func extractFormhashAndLogin(webView: WKWebView) {
        // Try to extract formhash from the page
        webView.evaluateJavaScript("document.querySelector('input[name=formhash]')?.value") { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                print("[Login] formhash JS error: \(error.localizedDescription)")
            }

            if let hash = result as? String, !hash.isEmpty {
                print("[Login] Found formhash: \(hash)")
                self.formhash = hash
                self.isLoggingIn = true
                self.performLogin()
            } else {
                // Try alternate methods
                print("[Login] formhash not found via JS, trying HTML parsing...")
                webView.evaluateJavaScript("document.body ? document.body.innerHTML.substring(0, 500) : 'no body'") { [weak self] htmlResult, _ in
                    guard let self = self else { return }

                    if let html = htmlResult as? String {
                        print("[Login] HTML preview: \(html.prefix(200))")

                        // Try to find formhash in HTML
                        if let range = html.range(of: "formhash\" value=\"") {
                            let startIndex = range.upperBound
                            let endIndex = html.index(startIndex, offsetBy: 40, limitedBy: html.endIndex) ?? html.endIndex
                            let substring = String(html[startIndex..<endIndex])
                            if let hashEnd = substring.firstIndex(of: "\"") {
                                let hash = String(substring[..<hashEnd])
                                print("[Login] Extracted formhash from HTML: \(hash)")
                                self.formhash = hash
                                self.isLoggingIn = true
                                self.performLogin()
                                return
                            }
                        }

                        // Check for Cloudflare or other challenges
                        if html.contains("cloudflare") || html.contains("challenge") || html.contains("Turnstile") {
                            print("[Login] Cloudflare challenge detected!")
                            self.updateLoadingMessage("正在通过安全验证...")
                        }
                    }

                    print("[Login] Failed to extract formhash, checking page state...")
                    webView.evaluateJavaScript("document.readyState + ' | ' + (document.querySelector('input[name=formhash]') ? 'has_formhash' : 'no_formhash')") { [weak self] stateResult, _ in
                        print("[Login] Page state: \(stateResult ?? "unknown")")
                    }

                    self.loginCompletion?(false, "无法获取登录表单，请检查网络后重试")
                    self.cleanup()
                }
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("[Login] Navigation failed: \(error.localizedDescription)")

        let nsError = error as NSError
        if nsError.code != NSURLErrorCancelled {
            loginCompletion?(false, error.localizedDescription)
            cleanup()
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print("[Login] Provisional navigation failed: \(error.localizedDescription)")

        let nsError = error as NSError
        if nsError.code == NSURLErrorCancelled {
            print("[Login] Cancelled provisional navigation (redirect), waiting...")
            return
        }

        if error.localizedDescription.contains("cancelled") {
            print("[Login] May be Cloudflare challenge, waiting...")
            return
        }

        loginCompletion?(false, error.localizedDescription)
        cleanup()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        if let response = navigationResponse.response as? HTTPURLResponse {
            print("[Login] Response: \(response.statusCode) - \(response.url?.absoluteString ?? "nil")")
        }
        decisionHandler(.allow)
    }

    private func handleLoginSuccess(webView: WKWebView) {
        updateLoadingMessage("登录成功，正在同步数据...")
        syncCookiesToSharedStorage(from: webView) { [weak self] hasCookies in
            guard let self = self else { return }

            print("[Login] After cookie sync - hasCookies: \(hasCookies)")

            if hasCookies {
                // First go to memcp.php to extract UID
                print("[Login] Proceeding to memcp.php to get UID...")
                let memcpURL = URL(string: "https://www.4d4y.com/forum/memcp.php")!
                webView.load(URLRequest(url: memcpURL))
            } else {
                self.loginCompletion?(false, "登录失败，未获取到有效的会话")
                self.cleanup()
            }
        }
    }

    private func extractUIDFromMemcp(webView: WKWebView) {
        webView.evaluateJavaScript("document.body.innerHTML") { [weak self] bodyResult, bodyError in
            guard let self = self else { return }

            if let bodyHtml = bodyResult as? String {
                print("[Login] memcp.php body HTML length: \(bodyHtml.count)")
            }

            // Extract both UID and username from the page
            let js = #"""
            (function() {
                var result = {uid: null, username: null};

                // Extract UID
                var umenu = document.getElementById('umenu');
                if (umenu) {
                    var links = umenu.querySelectorAll('a[href*="space.php?uid="]');
                    for (var i = 0; i < links.length; i++) {
                        var href = links[i].getAttribute('href');
                        var match = href.match(/uid=(\d+)/);
                        if (match && match[1]) {
                            result.uid = match[1];
                            // Also get username from link text
                            var linkText = links[i].textContent.trim();
                            if (linkText && linkText.length > 0 && linkText.length < 50) {
                                result.username = linkText;
                            }
                            break;
                        }
                    }
                }

                // If no username from umenu, try other links
                if (!result.username) {
                    var allLinks = document.querySelectorAll('a[href*="uid="]');
                    for (var i = 0; i < allLinks.length; i++) {
                        var href = allLinks[i].getAttribute('href');
                        var match = href.match(/uid=(\d+)/);
                        if (match && match[1]) {
                            result.uid = match[1];
                            var linkText = allLinks[i].textContent.trim();
                            if (linkText && linkText.length > 0 && linkText.length < 50 && !linkText.includes(' ')) {
                                result.username = linkText;
                                break;
                            }
                        }
                    }
                }

                // Try to get username from page title or header
                var headerUsername = document.querySelector('.headerusername') ||
                                   document.querySelector('.loginnames') ||
                                   document.querySelector('#umenu .fl');
                if (headerUsername && !result.username) {
                    var text = headerUsername.textContent.trim();
                    // Remove "欢迎 " prefix if present
                    if (text.indexOf(' ') > 0) {
                        text = text.substring(text.indexOf(' ') + 1);
                    }
                    if (text.length > 0 && text.length < 50) {
                        result.username = text;
                    }
                }

                return JSON.stringify(result);
            })();
            """#

            webView.evaluateJavaScript(js) { [weak self] result, error in
                guard let self = self else { return }

                print("[Login] UID/Username extraction result: \(result ?? "nil")")

                // Parse result
                var uid: Int?
                var username: String?

                if let jsonStr = result as? String,
                   let data = jsonStr.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let uidStr = json["uid"] as? String {
                        uid = Int(uidStr)
                    }
                    username = json["username"] as? String
                }

                // Save UID
                if let uid = uid {
                    print("[Login] Extracted UID: \(uid)")
                    LoginManager.shared.uid = uid
                }

                // Save username if found
                if let username = username, !username.isEmpty {
                    print("[Login] Extracted username: \(username)")
                    LoginManager.shared.username = username
                } else {
                    // Use stored credentials if available, otherwise use UID as fallback
                    let storedUsername = UserDefaults.standard.string(forKey: "forum_username")
                    if storedUsername == nil {
                        print("[Login] No username found, using UID as fallback")
                        LoginManager.shared.username = "User_\(uid ?? 0)"
                    }
                }

                // Complete login - UID extracted and cookies are synced
                print("[Login] Login completed successfully, notifying delegate...")
                self.updateLoadingMessage("登录成功!")

                // Set logged in state AND save login date so refreshLoginState doesn't clear it
                LoginManager.shared.loginDate = Date()
                LoginManager.shared.isLoggedIn = true

                // Notify delegate
                self.delegate?.loginViewControllerDidLogin(self)

                // Cleanup
                self.cleanup()
            }
        }
    }

    // Keep this for backwards compatibility but it's no longer used in the main flow
    private func proceedToForumPage(webView: WKWebView) {
        print("[Login] Proceeding to forum page...")
        self.forumListCompletion = { _ in }
        let forumURL = URL(string: "https://www.4d4y.com/forum/index.php")!
        webView.load(URLRequest(url: forumURL))
    }

    private func extractForumListHTML(from webView: WKWebView) {
        let js = #"""
        (function() {
            var forumTable = document.querySelector('table.forumlist') || document.querySelector('.forumlist');
            if (forumTable) {
                return forumTable.innerHTML;
            }
            var lists = document.querySelectorAll('.fl_ul, .forumlist, #forumlist');
            for (var i = 0; i < lists.length; i++) {
                if (lists[i].innerHTML.includes('fid=') || lists[i].innerHTML.includes('forumdisplay')) {
                    return lists[i].innerHTML;
                }
            }
            return document.body.innerHTML;
        })();
        """#

        webView.evaluateJavaScript(js) { [weak self] result, error in
            guard let self = self else { return }

            if let html = result as? String {
                print("[Login] Extracted forum HTML length: \(html.count)")

                if let forums = self.parseForumListHTML(html) {
                    print("[Login] Parsed \(forums.count) forums from HTML")

                    LoginManager.shared.saveCookies()

                    self.forumListCompletion?(forums)
                    self.delegate?.loginViewControllerDidLoginWithForumData(self, forums: forums)
                    self.loginCompletion?(true, nil)
                    self.cleanup()
                } else {
                    print("[Login] Failed to parse forum HTML")
                    self.loginCompletion?(false, "无法解析论坛数据")
                    self.cleanup()
                }
            } else {
                print("[Login] Failed to extract forum HTML: \(error?.localizedDescription ?? "unknown")")
                self.loginCompletion?(false, error?.localizedDescription ?? "获取论坛列表失败")
                self.cleanup()
            }
        }
    }
}

// MARK: - WKUIDelegate

extension LoginViewController: WKUIDelegate {

    func webView(_ webView: WKWebView, createWebViewConfigurationFor navigationAction: WKNavigationAction) -> WKWebViewConfiguration {
        return WKWebViewConfiguration()
    }

    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        print("[Login] JS Alert: \(message)")
        completionHandler()
    }
}
