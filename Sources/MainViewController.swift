import UIKit
import WebKit

class MainViewController: UIViewController {

    private var webView: WKWebView!
    private var progressView: UIProgressView!
    private var refreshControl: UIRefreshControl!
    private var loginOverlayView: UIView?
    private var isLoadingInitialPage = true
    
    private var pendingLoginUsername: String?
    private var pendingLoginPassword: String?
    private var pendingLoginAnswer: String?
    private var isLoggingIn = false
    
    private let forumURL = URL(string: "https://www.4d4y.com/forum/")!
    private var progressObservation: NSKeyValueObservation?
    
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
    
    private let mobileCSS = """
    @charset "utf-8";
    * {
        -webkit-text-size-adjust: 100% !important;
        box-sizing: border-box;
    }
    body {
        padding: 0 !important;
        margin: 0 !important;
        font-size: 16px !important;
        line-height: 1.6 !important;
        background: #ffffff !important;
        color: #1a1a1a !important;
        min-width: 100% !important;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif !important;
    }
    #header, #ad_headerbanner, #ad_text, #ad_footerbanner1, #ad_footerbanner2, #ad_footerbanner3, .adcontent, .headactions {
        display: none !important;
    }
    #nav {
        background: #007aff !important;
        padding: 12px 16px !important;
        font-size: 14px !important;
    }
    #nav a {
        color: #ffffff !important;
        text-decoration: none !important;
    }
    #wrap {
        margin: 0 !important;
        padding: 0 !important;
        width: 100% !important;
        max-width: 100% !important;
    }
    .main {
        width: 100% !important;
        margin: 0 !important;
        padding: 0 !important;
        float: none !important;
    }
    .content {
        padding: 0 !important;
    }
    .itemtitle, .forumheader {
        background: #f8f8f8 !important;
        padding: 14px 16px !important;
        margin: 0 0 8px 0 !important;
    }
    .itemtitle h3, .forumheader h1 {
        font-size: 17px !important;
        margin: 0 !important;
        padding: 0 !important;
        color: #007aff !important;
        font-weight: 600 !important;
    }
    .mainbox {
        background: #fff !important;
        border-radius: 0 !important;
        margin-bottom: 0 !important;
        border-bottom: 1px solid #e5e5e5 !important;
    }
    .mainbox table {
        width: 100% !important;
        border-collapse: collapse !important;
    }
    .mainbox thead {
        display: none !important;
    }
    .mainbox tbody tr {
        display: flex !important;
        flex-direction: column !important;
        padding: 14px 16px !important;
        border-bottom: 1px solid #f0f0f0 !important;
        text-decoration: none !important;
    }
    .mainbox tbody tr:last-child {
        border-bottom: none !important;
    }
    .mainbox tbody td {
        display: block !important;
        padding: 2px 0 !important;
        border: none !important;
        font-size: 14px !important;
    }
    .mainbox .folder, .mainbox .icon {
        display: none !important;
    }
    .mainbox .subject {
        order: 1 !important;
        margin-bottom: 6px !important;
    }
    .mainbox .subject a {
        font-size: 15px !important;
        color: #333 !important;
        text-decoration: none !important;
        line-height: 1.4 !important;
        display: -webkit-box !important;
        -webkit-line-clamp: 2 !important;
        -webkit-box-orient: vertical !important;
        overflow: hidden !important;
    }
    .mainbox .author {
        order: 2 !important;
        font-size: 12px !important;
        color: #999 !important;
    }
    .mainbox .nums {
        order: 3 !important;
        font-size: 12px !important;
        color: #666 !important;
    }
    .mainbox .nums strong {
        color: #007aff !important;
        font-weight: 600 !important;
    }
    .mainbox .lastpost {
        order: 4 !important;
        font-size: 12px !important;
        color: #999 !important;
        margin-top: 4px !important;
    }
    .mainbox .lastpost cite a {
        color: #007aff !important;
        text-decoration: none !important;
    }
    .pages, .pages_btns {
        display: flex !important;
        flex-wrap: wrap !important;
        gap: 6px !important;
        padding: 14px 16px !important;
        background: #fff !important;
        margin-bottom: 0 !important;
    }
    .pages a, .pages strong, .pages_btns a {
        display: inline-flex !important;
        align-items: center !important;
        justify-content: center !important;
        padding: 8px 14px !important;
        background: #f0f0f0 !important;
        border-radius: 6px !important;
        color: #333 !important;
        text-decoration: none !important;
        font-size: 14px !important;
        min-width: 40px !important;
    }
    .pages a:hover {
        background: #007aff !important;
        color: #fff !important;
    }
    .pages strong {
        background: #007aff !important;
        color: #fff !important;
    }
    .postauthor {
        width: 100% !important;
        padding: 14px 16px !important;
        background: #f8f8f8 !important;
        border-bottom: 1px solid #eee !important;
        display: flex !important;
        align-items: center !important;
        gap: 12px !important;
    }
    .postauthor .avatar img {
        width: 44px !important;
        height: 44px !important;
        border-radius: 50% !important;
        object-fit: cover !important;
    }
    .postauthor .postinfo {
        flex: 1 !important;
    }
    .postauthor .postinfo a {
        font-weight: 600 !important;
        font-size: 14px !important;
        color: #333 !important;
        text-decoration: none !important;
    }
    .postauthor p {
        margin: 2px 0 0 0 !important;
        font-size: 12px !important;
        color: #999 !important;
    }
    .postauthor dl.profile {
        display: none !important;
    }
    .postcontent {
        padding: 16px !important;
    }
    .postmessage {
        font-size: 15px !important;
        line-height: 1.7 !important;
        color: #333 !important;
    }
    .postmessage img {
        max-width: 100% !important;
        height: auto !important;
        display: block !important;
        margin: 8px 0 !important;
    }
    .postinfo {
        font-size: 12px !important;
        color: #999 !important;
        padding: 12px 16px !important;
        background: #f8f8f8 !important;
        border-top: 1px solid #eee !important;
    }
    .postinfo strong {
        font-weight: normal !important;
        color: #666 !important;
    }
    .postinfo em {
        color: #999 !important;
        font-style: normal !important;
    }
    .bdshare {
        display: none !important;
    }
    .quote, .blockcode {
        background: #f5f5f5 !important;
        border-radius: 6px !important;
        padding: 12px !important;
        margin: 8px 0 !important;
        font-size: 14px !important;
    }
    .quote {
        border-left: 3px solid #007aff !important;
    }
    .blockcode {
        border-left: 3px solid #ff9500 !important;
    }
    .blockcode code {
        white-space: pre-wrap !important;
        word-break: break-all !important;
    }
    input[type="text"], input[type="password"], textarea {
        font-size: 16px !important;
        padding: 12px !important;
        border: 1px solid #ddd !important;
        border-radius: 8px !important;
        width: 100% !important;
        margin-bottom: 12px !important;
        -webkit-appearance: none !important;
        background: #fff !important;
    }
    select {
        font-size: 16px !important;
        padding: 12px !important;
        border: 1px solid #ddd !important;
        border-radius: 8px !important;
        width: 100% !important;
        margin-bottom: 12px !important;
        background: #fff !important;
    }
    button, .btn, input[type="submit"], .submit {
        padding: 14px 24px !important;
        background: #007aff !important;
        color: #fff !important;
        border: none !important;
        border-radius: 8px !important;
        font-size: 16px !important;
        cursor: pointer !important;
        width: 100% !important;
    }
    #footer {
        padding: 16px !important;
        text-align: center !important;
        font-size: 12px !important;
        color: #999 !important;
        background: #f8f8f8 !important;
    }
    #fastpost {
        background: #fff !important;
        padding: 16px !important;
        margin: 12px !important;
        border-radius: 12px !important;
        border: 1px solid #e5e5e5 !important;
    }
    #fastpost textarea {
        border: 1px solid #ddd !important;
        border-radius: 8px !important;
        min-height: 100px !important;
        padding: 12px !important;
    }
    #fastpostsubmit {
        margin-top: 10px !important;
        width: auto !important;
        float: right !important;
    }
    .newspecial {
        display: inline-flex !important;
        align-items: center !important;
        padding: 10px 18px !important;
        background: #007aff !important;
        color: #fff !important;
        border-radius: 20px !important;
        text-decoration: none !important;
        font-size: 14px !important;
        margin: 10px !important;
    }
    .newspecial img {
        display: none !important;
    }
    .newspecial::before {
        content: '' !important;
    }
    a[href*="action=reply"], a[href*="post.php?action=reply"] {
        display: inline-flex !important;
        padding: 8px 14px !important;
        background: #34c759 !important;
        color: #fff !important;
        border-radius: 16px !important;
        text-decoration: none !important;
        font-size: 13px !important;
    }
    .viewthread_post {
        margin: 10px !important;
        background: #fff !important;
        border-radius: 12px !important;
        border: 1px solid #e5e5e5 !important;
        overflow: hidden !important;
    }
    .threadlist {
        background: #fff !important;
        border-radius: 12px !important;
        overflow: hidden !important;
        margin: 10px !important;
        border: 1px solid #e5e5e5 !important;
    }
    .postactions {
        display: flex !important;
        justify-content: space-between !important;
        padding: 12px 16px !important;
        background: #f8f8f8 !important;
        border-top: 1px solid #eee !important;
    }
    .postact {
        display: flex !important;
        gap: 10px !important;
    }
    .postact a {
        color: #007aff !important;
        text-decoration: none !important;
        font-size: 13px !important;
    }
    .Floathd, .float_wrap {
        background: #fff !important;
        border-radius: 12px !important;
        padding: 16px !important;
    }
    .savedata {
        display: none !important;
    }
    .p_bl, .p_cb {
        background: #fff !important;
        padding: 10px 14px !important;
        border-radius: 8px !important;
        margin: 8px !important;
    }
    .p_cb {
        border-left: 3px solid #ff9500 !important;
    }
    .psth {
        padding: 12px 16px !important;
        background: #f8f8f8 !important;
        border-bottom: 1px solid #eee !important;
        font-size: 13px !important;
        color: #666 !important;
    }
    .pcbs {
        padding: 12px 16px !important;
        background: #f8f8f8 !important;
        border-top: 1px solid #eee !important;
    }
    .mbn, #click_adv {
        display: none !important;
    }
    .signatures {
        font-size: 12px !important;
        color: #999 !important;
        padding: 12px 16px !important;
        border-top: 1px solid #f0f0f0 !important;
        margin-top: 12px !important;
    }
    .pageback, .forumstats {
        display: none !important;
    }
    """

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWebView()
        setupNavigationBar()
        injectMobileStyles()
        loadForum()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue

        progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)

        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 3)
        ])

        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshPage), for: .valueChanged)
    }

    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.refreshControl = refreshControl
        webView.scrollView.contentInsetAdjustmentBehavior = .always

        view.addSubview(webView)

        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])

        progressObservation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] webView, _ in
            let progress = Float(webView.estimatedProgress)
            self?.progressView.setProgress(progress, animated: true)
            if progress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self?.progressView.setProgress(0, animated: false)
                }
            }
        }
    }

    private func setupNavigationBar() {
        updateTitleAndButtons()
    }
    
    private func updateTitleAndButtons() {
        let fid = ForumManager.shared.lastVisitedFid
        title = ForumManager.shared.getForumDisplayName(fid)
        navigationController?.navigationBar.prefersLargeTitles = false

        let backButton = UIBarButtonItem(image: UIImage(systemName: "chevron.left"), style: .plain, target: self, action: #selector(goBack))
        let forwardButton = UIBarButtonItem(image: UIImage(systemName: "chevron.right"), style: .plain, target: self, action: #selector(goForward))
        let forumButton = UIBarButtonItem(image: UIImage(systemName: "list.bullet"), style: .plain, target: self, action: #selector(showForumPicker))
        
        var rightButtons: [UIBarButtonItem] = []
        
        if LoginManager.shared.isLoggedIn {
            let logoutButton = UIBarButtonItem(image: UIImage(systemName: "person.crop.circle.badge.xmark"), style: .plain, target: self, action: #selector(logoutTapped))
            let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(sharePage))
            let moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMoreOptions))
            rightButtons = [moreButton, shareButton, logoutButton]
        } else {
            let loginButton = UIBarButtonItem(image: UIImage(systemName: "person.crop.circle.badge.plus"), style: .plain, target: self, action: #selector(loginTapped))
            let shareButton = UIBarButtonItem(image: UIImage(systemName: "square.and.arrow.up"), style: .plain, target: self, action: #selector(sharePage))
            let moreButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), style: .plain, target: self, action: #selector(showMoreOptions))
            rightButtons = [moreButton, shareButton, loginButton]
        }
        
        navigationItem.leftBarButtonItems = [backButton, forwardButton, forumButton]
        navigationItem.rightBarButtonItems = rightButtons

        updateNavigationButtons()
    }

    private func injectMobileStyles() {
        let script = WKUserScript(source: mobileCSS, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        
        let viewportFix = WKUserScript(source: """
        let meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        if (!document.querySelector('meta[name="viewport"]')) {
            document.head.appendChild(meta);
        }
        document.documentElement.style.fontSize = '16px';
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(viewportFix)
        
        let clickEnhance = WKUserScript(source: """
        document.addEventListener('click', function(e) {
            let link = e.target.closest('a');
            if (link) {
                link.style.transition = 'opacity 0.2s';
                link.style.opacity = '0.7';
                setTimeout(function() { link.style.opacity = '1'; }, 150);
            }
        }, true);
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(clickEnhance)
        
        let popupHandler = WKUserScript(source: """
        (function() {
            window.showWindow = function(id, url, v) {
                var win = document.getElementById(id);
                if (!win) {
                    win = document.createElement('div');
                    win.id = id;
                    win.className = 'popupmenu_popup';
                    win.innerHTML = '<div class=\"popup_close\" onclick=\"hideWindow(\\'' + id + '\\')\">×</div><iframe src=\"' + url + '\" style=\"width:100%;height:300px;border:none;\"></iframe>';
                    document.body.appendChild(win);
                }
                win.style.display = 'block';
                
                var mask = document.createElement('div');
                mask.className = 'fwinmask';
                mask.id = 'mask_' + id;
                mask.onclick = function() { hideWindow(id); };
                document.body.appendChild(mask);
                
                return win;
            };
            
            window.hideWindow = function(id) {
                var win = document.getElementById(id);
                var mask = document.getElementById('mask_' + id);
                if (win) win.style.display = 'none';
                if (mask) mask.remove();
            };
            
            window.ajaxpost = function(formId, resultId, showErrorId, callback) {
                var form = document.getElementById(formId);
                if (!form) return false;
                
                var formData = new FormData(form);
                var xhr = new XMLHttpRequest();
                xhr.open('POST', form.action, true);
                xhr.onload = function() {
                    if (callback) callback(200);
                    else if (showErrorId) {
                        var result = document.getElementById(resultId);
                        if (result) result.innerHTML = xhr.responseText;
                    }
                };
                xhr.onerror = function() {
                    if (showErrorId) {
                        var result = document.getElementById(resultId);
                        if (result) result.innerHTML = '<span class=\"error\">提交失败</span>';
                    }
                };
                xhr.send(formData);
                return false;
            };
            
            document.addEventListener('DOMContentLoaded', function() {
                var newspecialLinks = document.querySelectorAll('.newspecial a, #newspecial a, a[href*=\"post.php?action=newthread\"]');
                newspecialLinks.forEach(function(link) {
                    link.textContent = '发帖';
                    link.style.display = 'inline-block';
                    link.style.padding = '10px 20px';
                    link.style.background = '#007aff';
                    link.style.color = '#fff';
                    link.style.borderRadius = '20px';
                    link.style.textDecoration = 'none';
                    var img = link.querySelector('img');
                    if (img) img.remove();
                });
                
                var replyLinks = document.querySelectorAll('a[href*=\"action=reply\"], a[href*=\"post.php?action=reply\"]');
                replyLinks.forEach(function(link) {
                    link.textContent = '回复';
                    link.style.display = 'inline-block';
                    link.style.padding = '8px 16px';
                    link.style.background = '#34c759';
                    link.style.color = '#fff';
                    link.style.borderRadius = '15px';
                    link.style.textDecoration = 'none';
                    link.style.fontSize = '14px';
                });
                
                var fastpostBtn = document.getElementById('fastpostsubmit');
                if (fastpostBtn) {
                    fastpostBtn.textContent = '发表回复';
                    fastpostBtn.style.background = '#007aff';
                    fastpostBtn.style.color = '#fff';
                    fastpostBtn.style.border = 'none';
                    fastpostBtn.style.padding = '12px 24px';
                    fastpostBtn.style.borderRadius = '8px';
                    fastpostBtn.style.cursor = 'pointer';
                }
            });
        })();
        """, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(popupHandler)
    }

    private func loadForum() {
        let url = ForumManager.shared.getLastVisitedURL()
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    private func navigateToForum(fid: Int) {
        ForumManager.shared.updateLastVisited(fid: fid)
        let url = ForumManager.shared.urlForForum(fid: fid)
        let request = URLRequest(url: url)
        webView.load(request)
        updateTitleAndButtons()
    }
    
    private func updateNavigationButtons() {
        if let leftBarButtonItems = navigationItem.leftBarButtonItems {
            leftBarButtonItems[0].isEnabled = webView.canGoBack
            leftBarButtonItems[1].isEnabled = webView.canGoForward
        }
    }
    
    @objc private func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @objc private func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    @objc private func goHome() {
        loadForum()
    }

    @objc private func sharePage() {
        if let url = webView.url {
            let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            if let popover = activityVC.popoverPresentationController {
                popover.barButtonItem = navigationItem.rightBarButtonItems?[1]
            }
            present(activityVC, animated: true)
        }
    }
    
    @objc private func loginTapped() {
        showLoginOverlay()
    }
    
    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "退出登录", message: "确定要退出当前账号吗？", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "退出", style: .destructive) { [weak self] _ in
            LoginManager.shared.clearCredentials()
            self?.webView.evaluateJavaScript("""
                window.location.reload();
            """)
            self?.updateTitleAndButtons()
            self?.loadForum()
        })
        present(alert, animated: true)
    }

    @objc private func showMoreOptions() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "🔄 刷新页面", style: .default) { [weak self] _ in
            self?.webView.reload()
        })
        
        if LoginManager.shared.username == nil || LoginManager.shared.password == nil {
            alert.addAction(UIAlertAction(title: "🔐 登录论坛", style: .default) { [weak self] _ in
                self?.showSaveCredentialsAlert()
            })
        } else if !LoginManager.shared.isLoggedIn {
            alert.addAction(UIAlertAction(title: "🔐 立即登录 (已保存账号)", style: .default) { [weak self] _ in
                self?.navigateToLoginPage()
            })
        } else {
            alert.addAction(UIAlertAction(title: "🔐 已登录: \(LoginManager.shared.username ?? "")", style: .default) { [weak self] _ in
                self?.checkLoginState()
            })
        }
        
        alert.addAction(UIAlertAction(title: "🌐 在Safari中打开", style: .default) { [weak self] _ in
            if let url = self?.webView.url {
                UIApplication.shared.open(url)
            }
        })
        
        alert.addAction(UIAlertAction(title: "📋 复制链接", style: .default) { [weak self] _ in
            if let url = self?.webView.url {
                UIPasteboard.general.string = url.absoluteString
            }
        })
        
        alert.addAction(UIAlertAction(title: "⚙️ 修改登录信息", style: .default) { [weak self] _ in
            self?.showSaveCredentialsAlert()
        })
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.rightBarButtonItems?[0]
        }
        
        present(alert, animated: true)
    }
    
    private func navigateToLoginPage() {
        let sidValue: UInt32 = .random(in: UInt32.min...UInt32.max)
        let loginURL = URL(string: "https://www.4d4y.com/forum/logging.php?action=login&sid=\(String(format: "%08X", sidValue))")!
        webView.load(URLRequest(url: loginURL))
        showToast("正在跳转登录页面...")
    }
    
    @objc private func showForumPicker() {
        let actionSheet = UIAlertController(title: "选择版块", message: nil, preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "论坛首页", style: .default) { [weak self] _ in
            self?.navigateToForum(fid: 0)
        })
        
        actionSheet.addAction(UIAlertAction(title: "收藏的版块", style: .default) { [weak self] _ in
            self?.showFavoriteForums()
        })
        
        actionSheet.addAction(UIAlertAction(title: "全部版块", style: .default) { [weak self] _ in
            self?.showAllForums()
        })
        
        actionSheet.addAction(UIAlertAction(title: "管理收藏", style: .default) { [weak self] _ in
            self?.showManageFavorites()
        })
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItems?[2]
        }
        
        present(actionSheet, animated: true)
    }
    
    private func showFavoriteForums() {
        let favoriteForums = ForumManager.shared.favoriteForums
        
        let actionSheet = UIAlertController(title: "★ 收藏的版块", message: "共 \(favoriteForums.count) 个收藏版块\n点击切换版块", preferredStyle: .actionSheet)
        
        if favoriteForums.isEmpty {
            actionSheet.addAction(UIAlertAction(title: "暂无收藏版块", style: .default) { [weak self] _ in
                self?.showManageFavorites()
            })
        } else {
            for forum in favoriteForums {
                let isSelected = ForumManager.shared.lastVisitedFid == forum.fid
                let title = isSelected ? "✓ \(forum.displayName)" : forum.displayName
                actionSheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                    self?.navigateToForum(fid: forum.fid)
                })
            }
        }
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItems?[2]
        }
        
        present(actionSheet, animated: true)
    }
    
    private func showAllForums() {
        let allForums = ForumManager.shared.allForums
        
        let actionSheet = UIAlertController(title: "全部版块", message: "共 \(allForums.count) 个版块\n★ = 已收藏 | 点击切换版块", preferredStyle: .actionSheet)
        
        for forum in allForums {
            let isFavorite = ForumManager.shared.isFavorite(forum.fid)
            let star = isFavorite ? "★" : "☆"
            let isSelected = ForumManager.shared.lastVisitedFid == forum.fid
            let title = isSelected ? "✓ \(star) \(forum.displayName)" : "\(star) \(forum.displayName)"
            actionSheet.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.navigateToForum(fid: forum.fid)
            })
        }
        
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel))
        
        if let popover = actionSheet.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItems?[2]
        }
        
        present(actionSheet, animated: true)
    }
    
    private func showManageFavorites() {
        let allForums = ForumManager.shared.allForums
        let favoriteFids = ForumManager.shared.favoriteFids
        
        let alert = UIAlertController(title: "管理收藏版块", message: "点击切换收藏状态", preferredStyle: .actionSheet)
        
        for forum in allForums {
            let isFavorite = favoriteFids.contains(forum.fid)
            let star = isFavorite ? "★" : "☆"
            alert.addAction(UIAlertAction(title: "\(star) \(forum.displayName)", style: .default) { [weak self] _ in
                ForumManager.shared.toggleFavorite(forum.fid)
                self?.showToast(isFavorite ? "已取消收藏" : "已添加收藏")
            })
        }
        
        alert.addAction(UIAlertAction(title: "完成", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.barButtonItem = navigationItem.leftBarButtonItems?[2]
        }
        
        present(alert, animated: true)
    }
    
    private func showSaveCredentialsAlert() {
        let alert = UIAlertController(title: "保存登录信息", message: "请输入论坛账号信息", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "用户名"
            textField.text = LoginManager.shared.username
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        alert.addTextField { textField in
            textField.placeholder = "密码"
            textField.text = LoginManager.shared.password
            textField.isSecureTextEntry = true
        }
        
        alert.addTextField { textField in
            textField.placeholder = "安全提示问题答案"
            textField.text = LoginManager.shared.answer
        }
        
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        alert.addAction(UIAlertAction(title: "保存", style: .default) { [weak self] _ in
            guard let username = alert.textFields?[0].text, !username.isEmpty,
                  let password = alert.textFields?[1].text, !password.isEmpty,
                  let answer = alert.textFields?[2].text else {
                return
            }
            
            LoginManager.shared.saveCredentials(
                username: username,
                password: password,
                questionId: 1,
                answer: answer
            )
            self?.showToast("登录信息已保存")
        })
        
        present(alert, animated: true)
    }
    
    private func showLoginOverlay() {
        let overlay = UIView(frame: view.bounds)
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.tag = 999
        
        let loginBox = UIView()
        loginBox.backgroundColor = .white
        loginBox.layer.cornerRadius = 16
        loginBox.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = "登录 4D4Y"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let errorLabel = UILabel()
        errorLabel.textColor = .systemRed
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.textAlignment = .center
        errorLabel.isHidden = true
        errorLabel.tag = 100
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let usernameField = UITextField()
        usernameField.placeholder = "用户名"
        usernameField.borderStyle = .roundedRect
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        usernameField.text = LoginManager.shared.username
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        
        let passwordField = UITextField()
        passwordField.placeholder = "密码"
        passwordField.borderStyle = .roundedRect
        passwordField.isSecureTextEntry = true
        passwordField.text = LoginManager.shared.password
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        
        let questionLabel = UILabel()
        questionLabel.text = "安全提示问题: 父亲出生的城市"
        questionLabel.font = .systemFont(ofSize: 14)
        questionLabel.textColor = .darkGray
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let answerField = UITextField()
        answerField.placeholder = "答案 (如: 安陆)"
        answerField.borderStyle = .roundedRect
        answerField.autocapitalizationType = .none
        answerField.autocorrectionType = .no
        answerField.text = LoginManager.shared.answer
        answerField.translatesAutoresizingMaskIntoConstraints = false
        
        let rememberSwitch = UISwitch()
        rememberSwitch.isOn = LoginManager.shared.isLoggedIn
        rememberSwitch.translatesAutoresizingMaskIntoConstraints = false
        
        let rememberLabel = UILabel()
        rememberLabel.text = "记住登录状态"
        rememberLabel.font = .systemFont(ofSize: 14)
        rememberLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let loginButton = UIButton(type: .system)
        loginButton.setTitle("登录", for: .normal)
        loginButton.backgroundColor = UIColor.systemBlue
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 8
        loginButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.addTarget(self, action: #selector(performLogin), for: .touchUpInside)
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.gray, for: .normal)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.addTarget(self, action: #selector(dismissLoginOverlay), for: .touchUpInside)
        
        overlay.addSubview(loginBox)
        loginBox.addSubview(titleLabel)
        loginBox.addSubview(errorLabel)
        loginBox.addSubview(usernameField)
        loginBox.addSubview(passwordField)
        loginBox.addSubview(questionLabel)
        loginBox.addSubview(answerField)
        loginBox.addSubview(rememberSwitch)
        loginBox.addSubview(rememberLabel)
        loginBox.addSubview(loginButton)
        loginBox.addSubview(cancelButton)
        
        usernameField.tag = 1
        passwordField.tag = 2
        answerField.tag = 3
        
        loginBox.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            loginBox.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            loginBox.centerYAnchor.constraint(equalTo: overlay.centerYAnchor),
            loginBox.widthAnchor.constraint(equalTo: overlay.widthAnchor, multiplier: 0.85),
            loginBox.widthAnchor.constraint(lessThanOrEqualToConstant: 360),
            
            titleLabel.topAnchor.constraint(equalTo: loginBox.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: loginBox.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: loginBox.trailingAnchor, constant: -16),
            
            errorLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            errorLabel.leadingAnchor.constraint(equalTo: loginBox.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: loginBox.trailingAnchor, constant: -16),
            
            usernameField.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 8),
            usernameField.leadingAnchor.constraint(equalTo: loginBox.leadingAnchor, constant: 16),
            usernameField.trailingAnchor.constraint(equalTo: loginBox.trailingAnchor, constant: -16),
            usernameField.heightAnchor.constraint(equalToConstant: 44),
            
            passwordField.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 12),
            passwordField.leadingAnchor.constraint(equalTo: loginBox.leadingAnchor, constant: 16),
            passwordField.trailingAnchor.constraint(equalTo: loginBox.trailingAnchor, constant: -16),
            passwordField.heightAnchor.constraint(equalToConstant: 44),
            
            questionLabel.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 16),
            questionLabel.leadingAnchor.constraint(equalTo: loginBox.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: loginBox.trailingAnchor, constant: -16),
            
            answerField.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 8),
            answerField.leadingAnchor.constraint(equalTo: loginBox.leadingAnchor, constant: 16),
            answerField.trailingAnchor.constraint(equalTo: loginBox.trailingAnchor, constant: -16),
            answerField.heightAnchor.constraint(equalToConstant: 44),
            
            rememberSwitch.topAnchor.constraint(equalTo: answerField.bottomAnchor, constant: 16),
            rememberSwitch.leadingAnchor.constraint(equalTo: loginBox.leadingAnchor, constant: 16),
            
            rememberLabel.centerYAnchor.constraint(equalTo: rememberSwitch.centerYAnchor),
            rememberLabel.leadingAnchor.constraint(equalTo: rememberSwitch.trailingAnchor, constant: 8),
            
            loginButton.topAnchor.constraint(equalTo: rememberSwitch.bottomAnchor, constant: 20),
            loginButton.leadingAnchor.constraint(equalTo: loginBox.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: loginBox.trailingAnchor, constant: -16),
            loginButton.heightAnchor.constraint(equalToConstant: 48),
            
            cancelButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 8),
            cancelButton.centerXAnchor.constraint(equalTo: loginBox.centerXAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: loginBox.bottomAnchor, constant: -16),
        ])
        
        loginOverlayView = overlay
        view.addSubview(overlay)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissLoginOverlay))
        overlay.addGestureRecognizer(tapGesture)
    }
    
    @objc private func dismissLoginOverlay() {
        clearPendingLogin()
        loginOverlayView?.removeFromSuperview()
        loginOverlayView = nil
    }
    
    @objc private func performLogin() {
        guard let overlay = loginOverlayView,
              let loginBox = overlay.subviews.first,
              let usernameField = loginBox.viewWithTag(1) as? UITextField,
              let passwordField = loginBox.viewWithTag(2) as? UITextField,
              let answerField = loginBox.viewWithTag(3) as? UITextField,
              let errorLabel = loginBox.viewWithTag(100) as? UILabel else {
            return
        }
        
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            errorLabel.text = "请填写用户名和密码"
            errorLabel.isHidden = false
            return
        }
        
        let answer = answerField.text ?? ""
        
        errorLabel.text = "正在登录..."
        errorLabel.isHidden = false
        
        pendingLoginUsername = username
        pendingLoginPassword = password
        pendingLoginAnswer = answer
        isLoggingIn = true
        
        let loginURL = URL(string: "https://www.4d4y.com/forum/logging.php?action=login")!
        webView.load(URLRequest(url: loginURL))
    }
    
    private func handleLoginPageLoaded() {
        guard isLoggingIn,
              let username = pendingLoginUsername,
              let password = pendingLoginPassword else { return }
        
        let answer = pendingLoginAnswer ?? ""
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.executeLogin(username: username, password: password, answer: answer)
        }
    }
    
    private func executeLogin(username: String, password: String, answer: String) {
        isLoggingIn = false
        
        webView.evaluateJavaScript("""
        (function() {
            var bodyHTML = document.body.innerHTML;
            var form = document.getElementById('loginform');
            if (!form) return {formhash: null, bodyPreview: bodyHTML.substring(0, 300)};
            var formhashInput = form.querySelector('input[name="formhash"]');
            return {formhash: formhashInput ? formhashInput.value : null, hasForm: true};
        })();
        """) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.showLoginError("获取表单失败: \(error.localizedDescription)")
                self.clearPendingLogin()
                return
            }
            
            guard let dict = result as? [String: Any] else {
                self.showLoginError("获取表单失败: 无法解析结果")
                self.clearPendingLogin()
                return
            }
            
            let hasForm = dict["hasForm"] as? Bool ?? false
            var formhash = ""
            if let hash = dict["formhash"] as? String {
                formhash = hash
            }
            
            if let preview = dict["bodyPreview"] as? String {
                print("Login debug - body preview: \(preview)")
            }
            
            print("Login debug - hasForm: \(hasForm), formhash: \(formhash)")
            
            if formhash.isEmpty {
                self.showLoginError("无法获取登录表单，可能是Cloudflare验证中，请稍等后重试")
                self.clearPendingLogin()
                return
            }
            
            self.performLoginWithWebView(username: username, password: password, answer: answer, formhash: formhash)
        }
    }
    
    private func clearPendingLogin() {
        pendingLoginUsername = nil
        pendingLoginPassword = nil
        pendingLoginAnswer = nil
        isLoggingIn = false
    }
    
    private func performLoginWithWebView(username: String, password: String, answer: String, formhash: String) {
        let js = """
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
                if (questionSelect) questionSelect.value = '0';
                if (answerField) answerField.value = '\(answer.escapedForJavaScript)';
                if (cookietime) cookietime.checked = true;
                
                var formhashInput = form.querySelector('input[name="formhash"]');
                if (formhashInput) formhashInput.value = '\(formhash)';
                
                var refererInput = form.querySelector('input[name="referer"]');
                if (refererInput) refererInput.value = 'https://www.4d4y.com/forum/index.php';
                
                form.submit();
                return {success: true};
            } catch(e) {
                return {success: false, error: e.message};
            }
        })();
        """
        
        webView.evaluateJavaScript(js) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.showLoginError("登录失败: \(error.localizedDescription)")
                    return
                }
                
                if let dict = result as? [String: Any], let success = dict["success"] as? Bool, success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.checkLoginState()
                    }
                } else {
                    var errorMsg = "登录失败"
                    if let dict = result as? [String: Any], let error = dict["error"] as? String {
                        errorMsg = "登录失败: \(error)"
                    }
                    self.showLoginError(errorMsg)
                }
            }
        }
    }

    @objc private func refreshPage() {
        webView.reload()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.refreshControl.endRefreshing()
        }
    }
    
    private func showToast(_ message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = 20
        toastLabel.clipsToBounds = true
        toastLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(toastLabel)
        
        NSLayoutConstraint.activate([
            toastLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toastLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            toastLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 150),
            toastLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 2, options: [], animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }
}

extension MainViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateNavigationButtons()
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateNavigationButtons()
        
        if let title = webView.title, !title.isEmpty {
            self.title = title.count > 15 ? String(title.prefix(15)) + "..." : title
        }
        
        checkLoginState()
        
        if isLoggingIn {
            handleLoginPageLoaded()
            return
        }
        
        if LoginManager.shared.username != nil && LoginManager.shared.password != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.checkAndAutoFillLogin()
            }
        }
        
        isLoadingInitialPage = false
    }
    
    private func checkAndAutoFillLogin() {
        webView.evaluateJavaScript("""
        (function() {
            var form = document.getElementById('loginform');
            var hasMD5 = typeof hex_md5 === 'function';
            return { 
                hasForm: !!form, 
                hasMD5: hasMD5,
                discuzUid: typeof discuz_uid !== 'undefined' ? discuz_uid : 0
            };
        })();
        """) { [weak self] result, error in
            guard let self = self else { return }
            
            if let dict = result as? [String: Any] {
                let hasForm = dict["hasForm"] as? Bool ?? false
                let hasMD5 = dict["hasMD5"] as? Bool ?? false
                let discuzUid = dict["discuzUid"] as? Int ?? 0
                
                if discuzUid > 0 {
                    LoginManager.shared.isLoggedIn = true
                    // Clear forum list cache so it refreshes with logged-in data
                    CacheManager.shared.clearCache(forKey: CacheManager.CacheKeys.forumList())
                    self.updateTitleAndButtons()
                    return
                }
                
                if hasForm {
                    if hasMD5 {
                        self.autoFillLoginForm()
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                            self?.autoFillLoginForm()
                        }
                    }
                }
            }
        }
    }
    
    private func autoFillLoginForm() {
        webView.evaluateJavaScript(LoginManager.shared.getLoginJavaScript() ?? "") { [weak self] result, error in
            guard let dict = result as? [String: Any],
                  let success = dict["success"] as? Bool, success else {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.submitLoginForm()
            }
        }
    }
    
    private func submitLoginForm() {
        webView.evaluateJavaScript("""
        (function() {
            try {
                var form = document.getElementById('loginform');
                if (!form) return {status: 'no_form'};
                
                var passwordField = document.getElementById('password3');
                if (passwordField && passwordField.value.length !== 32) {
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
        """) { [weak self] result, error in
            if let dict = result as? [String: Any],
               let status = dict["status"] as? String {
                print("Login submit status: \(status)")
                if status == "submitted" {
                    self?.showToast("正在登录...")
                }
            }
        }
    }
    
    private func checkLoginState() {
        webView.evaluateJavaScript(LoginManager.shared.getCheckLoginStatusJavaScript()) { [weak self] result, error in
            guard let self = self else { return }

            if let dict = result as? [String: Any] {
                let isLoggedIn = dict["loggedIn"] as? Bool ?? false
                let username = dict["username"] as? String

                DispatchQueue.main.async {
                    if isLoggedIn {
                        LoginManager.shared.isLoggedIn = true
                        // Clear forum list cache so it refreshes with logged-in data
                        CacheManager.shared.clearCache(forKey: CacheManager.CacheKeys.forumList())
                        if let name = username {
                            LoginManager.shared.username = name
                        }
                        // Sync cookies from WKWebView to HTTPCookieStorage.shared
                        self.syncCookiesFromWebView()
                    }
                    self.updateTitleAndButtons()
                }
            }
        }
    }

    private func syncCookiesFromWebView() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { cookies in
            print("[MainVC] WKWebView cookies count: \(cookies.count)")
            for cookie in cookies {
                print("[MainVC] Cookie: \(cookie.name)=\(cookie.value.prefix(30))... domain=\(cookie.domain)")
            }

            let storage = HTTPCookieStorage.shared
            var syncedCount = 0
            for cookie in cookies {
                // Only sync cookies for 4d4y.com domain
                if cookie.domain.contains("4d4y.com") {
                    if let existingCookie = storage.cookies?.first(where: { $0.name == cookie.name }) {
                        storage.deleteCookie(existingCookie)
                    }
                    storage.setCookie(cookie)
                    syncedCount += 1
                }
            }
            print("[MainVC] Synced \(syncedCount) cookies to HTTPCookieStorage.shared")

            // Also check for cdb_auth specifically
            let hasAuth = cookies.contains { $0.name == "cdb_auth" }
            print("[MainVC] Has cdb_auth cookie: \(hasAuth)")

            // Save cookies for persistence
            LoginManager.shared.saveCookies()
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        updateNavigationButtons()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        if let url = webView.url {
            if url.path.contains("forumdisplay") || url.path.contains("viewthread") || url.path.contains("index.php") {
                let fid = extractFidFromURL(url)
                if fid > 0 {
                    ForumManager.shared.updateLastVisited(fid: fid)
                    title = ForumManager.shared.getForumDisplayName(fid)
                }
            }
            checkLoginState()
        }
    }
    
    private func extractFidFromURL(_ url: URL) -> Int {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let queryItems = components.queryItems {
            if let fidStr = queryItems.first(where: { $0.name == "fid" })?.value,
               let fid = Int(fidStr) {
                return fid
            }
            if let fidStr = queryItems.first(where: { $0.name == "tid" })?.value,
               let _ = Int(fidStr) {
                return ForumManager.shared.lastVisitedFid
            }
        }
        return 0
    }
    
    func webView(_ webView: WKWebView, authenticationChallenge challenge: URLAuthenticationChallenge, shouldAllowCorporateBrowsing: Bool) -> Bool {
        return true
    }
    
    private func showLoginError(_ message: String) {
        guard let overlay = loginOverlayView,
              let loginBox = overlay.subviews.first,
              let errorLabel = loginBox.viewWithTag(100) as? UILabel else { return }
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}