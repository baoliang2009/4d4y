import UIKit
import SwiftSoup
import PhotosUI

protocol NewThreadViewControllerDelegate: AnyObject {
    func newThreadViewControllerDidPost(_ controller: NewThreadViewController)
}

class NewThreadViewController: UIViewController {

    weak var delegate: NewThreadViewControllerDelegate?

    private let fid: Int
    private let titleTextField = UITextField()
    private let contentTextView = UITextView()
    private let typeidButton = UIButton(type: .system)
    private let tagsTextField = UITextField()
    private let attachmentButton = UIButton(type: .system)
    private let attachmentCollectionView: UICollectionView
    private let uploadStatusLabel = UILabel()
    private let uploadProgressView = UIProgressView(progressViewStyle: .default)
    private let postButton = UIButton(type: .system)
    private let loadingIndicator = UIActivityIndicatorView(style: .medium)

    private var formhash: String?
    private var uploadHash: String?
    private var typeid: Int = 0
    private var isSubmitting = false

    private var selectedImages: [UIImage] = []
    private var uploadedAttachmentIds: [String] = []
    private var typeidOptions: [(id: Int, name: String)] = []

    private let gbkEncoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))

    init(fid: Int) {
        self.fid = fid

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 80)
        layout.minimumInteritemSpacing = 8
        self.attachmentCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPrePostPage()
        setupKeyboardHandling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        removeKeyboardObservers()
    }

    // MARK: - Keyboard

    private func setupKeyboardHandling() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        additionalSafeAreaInsets.bottom = keyboardFrame.height
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    @objc private func keyboardWillHide(_ notification: Notification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        additionalSafeAreaInsets.bottom = 0
        UIView.animate(withDuration: duration) { self.view.layoutIfNeeded() }
    }

    // MARK: - UI

    private func setupUI() {
        view.backgroundColor = Theme.currentBackground
        title = "发布帖子"

        titleTextField.placeholder = "请输入标题"
        titleTextField.font = .systemFont(ofSize: 18)
        titleTextField.textColor = Theme.currentForeground
        titleTextField.backgroundColor = Theme.currentMuted
        titleTextField.layer.cornerRadius = 8
        titleTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        titleTextField.leftViewMode = .always
        titleTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        titleTextField.rightViewMode = .always
        view.addSubview(titleTextField)

        typeidButton.setTitle("选择分类", for: .normal)
        typeidButton.titleLabel?.font = .systemFont(ofSize: 16)
        typeidButton.setTitleColor(Theme.currentForeground, for: .normal)
        typeidButton.backgroundColor = Theme.currentMuted
        typeidButton.layer.cornerRadius = 8
        typeidButton.contentHorizontalAlignment = .left
        typeidButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        typeidButton.addTarget(self, action: #selector(typeidTapped), for: .touchUpInside)
        view.addSubview(typeidButton)

        tagsTextField.placeholder = "标签（可选，多个用逗号分隔）"
        tagsTextField.font = .systemFont(ofSize: 16)
        tagsTextField.textColor = Theme.currentForeground
        tagsTextField.backgroundColor = Theme.currentMuted
        tagsTextField.layer.cornerRadius = 8
        tagsTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tagsTextField.leftViewMode = .always
        tagsTextField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0))
        tagsTextField.rightViewMode = .always
        view.addSubview(tagsTextField)

        contentTextView.font = .systemFont(ofSize: 16)
        contentTextView.textColor = Theme.currentForeground
        contentTextView.backgroundColor = Theme.currentMuted
        contentTextView.layer.cornerRadius = 8
        contentTextView.textContainerInset = UIEdgeInsets(top: 12, left: 8, bottom: 12, right: 8)
        view.addSubview(contentTextView)

        attachmentButton.setImage(UIImage(systemName: "photo"), for: .normal)
        attachmentButton.addTarget(self, action: #selector(attachmentTapped), for: .touchUpInside)
        view.addSubview(attachmentButton)

        uploadStatusLabel.font = .systemFont(ofSize: 13)
        uploadStatusLabel.textColor = Theme.currentSecondaryText
        uploadStatusLabel.isHidden = true
        view.addSubview(uploadStatusLabel)

        uploadProgressView.isHidden = true
        uploadProgressView.progressTintColor = Theme.primary
        uploadProgressView.trackTintColor = Theme.currentMuted
        view.addSubview(uploadProgressView)

        attachmentCollectionView.backgroundColor = .clear
        attachmentCollectionView.delegate = self
        attachmentCollectionView.dataSource = self
        attachmentCollectionView.register(NewThreadImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        attachmentCollectionView.isHidden = true
        view.addSubview(attachmentCollectionView)

        postButton.setTitle("发布", for: .normal)
        postButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        postButton.backgroundColor = Theme.primary
        postButton.setTitleColor(Theme.primaryForeground, for: .normal)
        postButton.layer.cornerRadius = 8
        postButton.addTarget(self, action: #selector(postTapped), for: .touchUpInside)
        view.addSubview(postButton)

        loadingIndicator.hidesWhenStopped = true
        view.addSubview(loadingIndicator)

        setupConstraints()
    }

    private func setupConstraints() {
        for v: UIView in [titleTextField, typeidButton, tagsTextField, contentTextView, attachmentButton, uploadStatusLabel, uploadProgressView, attachmentCollectionView, postButton, loadingIndicator] {
            v.translatesAutoresizingMaskIntoConstraints = false
        }

        NSLayoutConstraint.activate([
            titleTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            titleTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            titleTextField.heightAnchor.constraint(equalToConstant: 48),

            typeidButton.topAnchor.constraint(equalTo: titleTextField.bottomAnchor, constant: 12),
            typeidButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            typeidButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            typeidButton.heightAnchor.constraint(equalToConstant: 44),

            tagsTextField.topAnchor.constraint(equalTo: typeidButton.bottomAnchor, constant: 12),
            tagsTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            tagsTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tagsTextField.heightAnchor.constraint(equalToConstant: 44),

            contentTextView.topAnchor.constraint(equalTo: tagsTextField.bottomAnchor, constant: 12),
            contentTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            contentTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            contentTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 150),

            attachmentButton.topAnchor.constraint(equalTo: contentTextView.bottomAnchor, constant: 12),
            attachmentButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            attachmentButton.widthAnchor.constraint(equalToConstant: 44),
            attachmentButton.heightAnchor.constraint(equalToConstant: 44),

            attachmentCollectionView.centerYAnchor.constraint(equalTo: attachmentButton.centerYAnchor),
            attachmentCollectionView.leadingAnchor.constraint(equalTo: attachmentButton.trailingAnchor, constant: 12),
            attachmentCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            attachmentCollectionView.heightAnchor.constraint(equalToConstant: 80),

            uploadStatusLabel.topAnchor.constraint(equalTo: attachmentButton.bottomAnchor, constant: 8),
            uploadStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            uploadStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),

            uploadProgressView.topAnchor.constraint(equalTo: uploadStatusLabel.bottomAnchor, constant: 8),
            uploadProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            uploadProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            uploadProgressView.heightAnchor.constraint(equalToConstant: 4),

            postButton.topAnchor.constraint(equalTo: uploadProgressView.bottomAnchor, constant: 12),
            postButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            postButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            postButton.heightAnchor.constraint(equalToConstant: 48),

            loadingIndicator.centerXAnchor.constraint(equalTo: postButton.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: postButton.centerYAnchor),
        ])
    }

    // MARK: - Load Pre-Post Page (URLSession + SwiftSoup)

    private func loadPrePostPage() {
        let urlString = "https://www.4d4y.com/forum/post.php?action=newthread&fid=\(fid)"

        guard let url = URL(string: urlString) else { return }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.setValue("https://www.4d4y.com/forum/forumdisplay.php?fid=\(fid)", forHTTPHeaderField: "Referer")

        print("[NewThread] Loading pre-post page via URLSession: \(urlString)")

        NetworkManager.shared.session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                print("[NewThread] Pre-post page fetch failed: \(error.localizedDescription)")
                return
            }

            guard let data = data, let html = self.decodeResponseData(data) else {
                print("[NewThread] Failed to decode pre-post page")
                return
            }

            print("[NewThread] Pre-post page loaded, HTML length: \(html.count)")

            do {
                let doc = try SwiftSoup.parse(html)

                var fh: String?
                var uh: String?

                if let el = try doc.select("input[name=formhash]").first() {
                    let v = try el.attr("value")
                    if !v.isEmpty { fh = v }
                }

                for sel in ["#imgattachform input[name=hash]", "#attachform input[name=hash]", "input[name=hash]"] {
                    if let el = try doc.select(sel).first() {
                        let v = try el.attr("value")
                        if !v.isEmpty { uh = v; break }
                    }
                }

                if uh == nil {
                    uh = self.extractHashFromJavaScript(html)
                }

                // Extract typeid options
                var options: [(id: Int, name: String)] = []
                if let select = try doc.select("#typeid").first() ?? doc.select("select[name=typeid]").first() {
                    let optionElements = try select.select("option")
                    for opt in optionElements {
                        let val = try opt.attr("value")
                        let text = try opt.text().trimmingCharacters(in: .whitespacesAndNewlines)
                        if let id = Int(val), id > 0 && !text.isEmpty {
                            options.append((id: id, name: text))
                        }
                    }
                }

                DispatchQueue.main.async {
                    self.formhash = fh
                    self.uploadHash = uh
                    if !options.isEmpty {
                        self.typeidOptions = options
                    }

                    if let fh = fh { print("[NewThread] formhash: \(fh)") }
                    if let uh = uh { print("[NewThread] uploadHash: \(uh)") }
                    print("[NewThread] Found \(options.count) typeid options")
                }
            } catch {
                print("[NewThread] SwiftSoup parse error: \(error)")
            }
        }.resume()
    }

    private func extractHashFromJavaScript(_ html: String) -> String? {
        let patterns = [
            "\"hash\"\\s*:\\s*\"([a-f0-9]{16,})\"",
            "'hash'\\s*:\\s*'([a-f0-9]{16,})'",
            "hash=([a-f0-9]{16,})",
            "name=\"hash\"\\s+value=\"([a-f0-9]{16,})\"",
            "value=\"([a-f0-9]{16,})\"\\s+name=\"hash\"",
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               let range = Range(match.range(at: 1), in: html) {
                let hash = String(html[range])
                print("[NewThread] Found upload hash via JS regex: \(hash)")
                return hash
            }
        }
        return nil
    }

    // MARK: - Actions

    @objc private func typeidTapped() {
        guard !typeidOptions.isEmpty else {
            showAlert(title: "提示", message: "正在加载分类，请稍后再试")
            return
        }

        let alert = UIAlertController(title: "选择分类", message: nil, preferredStyle: .actionSheet)
        for option in typeidOptions {
            alert.addAction(UIAlertAction(title: option.name, style: .default) { [weak self] _ in
                self?.typeid = option.id
                self?.typeidButton.setTitle(option.name, for: .normal)
            })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func attachmentTapped() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func postTapped() {
        guard !isSubmitting else { return }

        guard let title = titleTextField.text, !title.isEmpty else {
            showAlert(title: "错误", message: "请输入标题")
            return
        }

        guard let content = contentTextView.text, !content.isEmpty else {
            showAlert(title: "错误", message: "请输入内容")
            return
        }

        guard formhash != nil else {
            showAlert(title: "提示", message: "正在加载表单数据，请稍后再试")
            return
        }

        isSubmitting = true
        loadingIndicator.startAnimating()
        postButton.setTitle("", for: .normal)
        postButton.isEnabled = false

        if !selectedImages.isEmpty {
            uploadImagesAndPost(title: title, content: content)
        } else {
            doSubmitPost(title: title, content: content)
        }
    }

    // MARK: - Image Upload

    private func uploadImagesAndPost(title: String, content: String) {
        if let hash = uploadHash {
            doUploadImages(title: title, content: content, hash: hash)
        } else {
            extractUploadHash { [weak self] extractedHash in
                guard let self = self else { return }
                if let hash = extractedHash {
                    self.uploadHash = hash
                    self.doUploadImages(title: title, content: content, hash: hash)
                } else {
                    self.isSubmitting = false
                    self.resetPostButton()
                    self.showAlert(title: "错误", message: "无法获取上传标识，请稍后重试")
                }
            }
        }
    }

    private func extractUploadHash(completion: @escaping (String?) -> Void) {
        let urlString = "https://www.4d4y.com/forum/post.php?action=newthread&fid=\(fid)"

        guard let url = URL(string: urlString) else { completion(nil); return }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")

        NetworkManager.shared.session.dataTask(with: request) { [weak self] data, _, _ in
            guard let self = self, let data = data, let html = self.decodeResponseData(data) else {
                DispatchQueue.main.async { completion(nil) }
                return
            }

            do {
                let doc = try SwiftSoup.parse(html)
                var foundHash: String?
                for sel in ["#imgattachform input[name=hash]", "#attachform input[name=hash]", "input[name=hash]"] {
                    if let el = try doc.select(sel).first() {
                        let v = try el.attr("value")
                        if !v.isEmpty {
                            foundHash = v
                            break
                        }
                    }
                }

                if foundHash == nil {
                    foundHash = self.extractHashFromJavaScript(html)
                }

                if let hash = foundHash {
                    print("[NewThread] extractUploadHash found: \(hash)")
                    DispatchQueue.main.async { completion(hash) }
                    return
                }
            } catch {
                print("[NewThread] extractUploadHash parse error: \(error)")
            }

            DispatchQueue.main.async { completion(nil) }
        }.resume()
    }

    private func doUploadImages(title: String, content: String, hash: String) {
        let total = selectedImages.count
        var completedCount = 0
        var uploadedIds: [String] = []
        var failedCount = 0

        DispatchQueue.main.async {
            self.uploadStatusLabel.isHidden = false
            self.uploadProgressView.isHidden = false
            self.uploadProgressView.progress = 0.0
            self.uploadStatusLabel.textColor = Theme.secondaryText
            self.uploadStatusLabel.text = "正在上传图片 (0/\(total))..."
        }

        let group = DispatchGroup()

        for (index, image) in selectedImages.enumerated() {
            group.enter()
            uploadImage(image, hash: hash) { [weak self] result in
                guard let self = self else { group.leave(); return }
                switch result {
                case .success(let attachmentId):
                    uploadedIds.append(attachmentId)
                    print("[NewThread] Uploaded image \(index + 1): \(attachmentId)")
                case .failure(let error):
                    failedCount += 1
                    print("[NewThread] Failed to upload image \(index + 1): \(error)")
                }
                completedCount += 1
                DispatchQueue.main.async {
                    self.uploadStatusLabel.text = "正在上传图片 (\(completedCount)/\(total))..."
                    self.uploadProgressView.setProgress(Float(completedCount) / Float(total), animated: true)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            if failedCount > 0 && uploadedIds.isEmpty {
                self.uploadStatusLabel.textColor = .systemRed
                self.uploadStatusLabel.text = "图片上传全部失败"
                self.isSubmitting = false
                self.resetPostButton()
                self.showAlert(title: "上传失败", message: "\(failedCount) 张图片上传失败，请重试")
                return
            }

            if failedCount > 0 {
                self.uploadStatusLabel.textColor = .systemOrange
                self.uploadStatusLabel.text = "已上传 \(uploadedIds.count)/\(total) 张，\(failedCount) 张失败"
            } else {
                self.uploadStatusLabel.textColor = .systemGreen
                self.uploadStatusLabel.text = "全部 \(total) 张图片上传成功"
            }

            self.uploadedAttachmentIds = uploadedIds
            self.doSubmitPost(title: title, content: content)
        }
    }

    // MARK: - Native HTTP POST Submission

    private func doSubmitPost(title: String, content: String) {
        guard let formhash = formhash else {
            handleSubmitError("formhash 缺失")
            return
        }

        var params: [(String, String)] = [
            ("formhash", formhash),
            ("posttime", String(Int(Date().timeIntervalSince1970))),
            ("wysiwyg", "0"),
            ("usesig", "1"),
            ("subject", title),
            ("message", content),
            ("attention_add", "1"),
        ]

        if let tags = tagsTextField.text, !tags.isEmpty {
            params.append(("tags", tags))
        }

        for attachId in uploadedAttachmentIds {
            params.append(("attachnew[\(attachId)][description]", ""))
        }

        let typeidParam = typeid > 0 ? "&typeid=\(typeid)" : ""
        let urlString = "https://www.4d4y.com/forum/post.php?action=newthread&fid=\(fid)\(typeidParam)&topicsubmit=yes"
        guard let url = URL(string: urlString) else {
            handleSubmitError("无效的URL")
            return
        }

        guard let bodyData = buildGBKFormBody(params) else {
            handleSubmitError("编码失败")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.4d4y.com/forum/post.php?action=newthread&fid=\(fid)", forHTTPHeaderField: "Referer")
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        request.httpBody = bodyData

        print("[NewThread] Submitting via native POST to: \(urlString)")
        print("[NewThread] formhash used: \(formhash)")

        NetworkManager.shared.session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }

            if let error = error {
                DispatchQueue.main.async { self.handleSubmitError("网络错误: \(error.localizedDescription)") }
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                let finalURL = httpResponse.url?.absoluteString ?? ""
                print("[NewThread] Response status: \(httpResponse.statusCode), finalURL: \(finalURL)")

                if finalURL.contains("viewthread.php") || finalURL.contains("forumdisplay.php") {
                    print("[NewThread] Redirect to thread page detected - success")
                    DispatchQueue.main.async { self.handleSubmitSuccess() }
                    return
                }
            }

            if let data = data, let html = self.decodeResponseData(data) {
                print("[NewThread] Response HTML length: \(html.count)")
                print("[NewThread] Response preview: \(html.prefix(500))")

                if html.contains("alert_right") {
                    print("[NewThread] Found alert_right - success")
                    DispatchQueue.main.async { self.handleSubmitSuccess() }
                    return
                }

                if html.contains("url=viewthread") || html.contains("url=forumdisplay") {
                    print("[NewThread] Found meta refresh to viewthread - success")
                    DispatchQueue.main.async { self.handleSubmitSuccess() }
                    return
                }

                if html.contains("succeedhandle") || html.contains("post_newthread_succeed") {
                    print("[NewThread] Found succeed handler - success")
                    DispatchQueue.main.async { self.handleSubmitSuccess() }
                    return
                }

                if html.contains("发帖成功") || html.contains("发布成功") || html.contains("非常感谢") {
                    print("[NewThread] Found success text - success")
                    DispatchQueue.main.async { self.handleSubmitSuccess() }
                    return
                }

                if let errorMsg = self.extractErrorMessage(from: html) {
                    print("[NewThread] Found error message: \(errorMsg)")
                    DispatchQueue.main.async { self.handleSubmitError(errorMsg) }
                    return
                }
            }

            DispatchQueue.main.async { self.handleSubmitError("提交失败，请重试") }
        }.resume()
    }

    // MARK: - GBK Encoding Helpers

    private func buildGBKFormBody(_ params: [(String, String)]) -> Data? {
        var parts: [String] = []
        for (key, value) in params {
            guard let encodedValue = gbkPercentEncode(value) else { return nil }
            parts.append("\(key)=\(encodedValue)")
        }
        return parts.joined(separator: "&").data(using: .ascii)
    }

    private func gbkPercentEncode(_ string: String) -> String? {
        guard let data = string.data(using: gbkEncoding) else { return nil }
        var encoded = ""
        for byte in data {
            let ch = Character(UnicodeScalar(byte))
            if ch.isASCII && (ch.isLetter || ch.isNumber || "-._~".contains(ch)) {
                encoded.append(ch)
            } else {
                encoded += String(format: "%%%02X", byte)
            }
        }
        return encoded
    }

    private func decodeResponseData(_ data: Data) -> String? {
        let gb18030 = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue)))
        return String(data: data, encoding: gb18030) ?? String(data: data, encoding: .utf8)
    }

    private func extractErrorMessage(from html: String) -> String? {
        if let mtRange = html.range(of: "messagetext") {
            let afterMt = html[mtRange.upperBound...]
            if let pStart = afterMt.range(of: "<p>"),
               let pEnd = html[pStart.upperBound...].range(of: "</p>") {
                let content = String(html[pStart.upperBound..<pEnd.lowerBound])
                let cleaned = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty { return cleaned }
            }
        }

        let patterns = ["alert_error", "alert_info"]
        for pattern in patterns {
            if let range = html.range(of: pattern),
               let divStart = html[range.lowerBound...].range(of: ">"),
               let divEnd = html[divStart.upperBound...].range(of: "</div>") {
                let content = String(html[divStart.upperBound..<divEnd.lowerBound])
                let cleaned = content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression).trimmingCharacters(in: .whitespacesAndNewlines)
                if !cleaned.isEmpty { return cleaned }
            }
        }
        return nil
    }

    // MARK: - Result Handling

    private func handleSubmitSuccess() {
        print("[NewThread] Submit success!")
        isSubmitting = false
        loadingIndicator.stopAnimating()
        delegate?.newThreadViewControllerDidPost(self)
        dismiss(animated: true)
    }

    private func handleSubmitError(_ message: String) {
        print("[NewThread] Submit error: \(message)")
        isSubmitting = false
        loadingIndicator.stopAnimating()
        resetPostButton()
        showAlert(title: "提交失败", message: message)
    }

    private func resetPostButton() {
        postButton.setTitle("发布", for: .normal)
        postButton.isEnabled = true
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }

    private func updateAttachmentUI() {
        attachmentCollectionView.isHidden = selectedImages.isEmpty
        attachmentCollectionView.reloadData()
    }

    // MARK: - Image Compression (matching hipda)

    private func compressImageForUpload(_ image: UIImage) -> Data? {
        let maxDimension: CGFloat = 2560
        let maxFileSize = 2 * 1024 * 1024
        let quality: CGFloat = 0.8

        var workingImage = scaleDown(image, maxDimension: maxDimension)
        guard var data = workingImage.jpegData(compressionQuality: quality) else { return nil }

        print("[NewThread] Initial compressed size: \(data.count / 1024)KB, dimensions: \(workingImage.size.width)x\(workingImage.size.height)")

        for i in 0..<5 {
            if data.count <= maxFileSize { break }
            let dim = maxDimension * CGFloat(5 - i) * 0.1
            workingImage = scaleDown(image, maxDimension: dim)
            guard let newData = workingImage.jpegData(compressionQuality: quality) else { break }
            data = newData
            print("[NewThread] Reduced to \(data.count / 1024)KB at \(Int(dim))px max dimension")
        }

        return data
    }

    private func scaleDown(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let maxSide = max(image.size.width, image.size.height)
        guard maxSide > maxDimension else { return image }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: round(image.size.width * scale), height: round(image.size.height * scale))

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Image Upload (multipart POST)

    private func uploadImage(_ image: UIImage, hash: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let imageData = compressImageForUpload(image) else {
            completion(.failure(NSError(domain: "ImageError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }

        print("[NewThread] Uploading image: \(imageData.count / 1024)KB")

        let uid = LoginManager.shared.uid
        guard uid > 0 else {
            completion(.failure(NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not logged in"])))
            return
        }

        let urlString = "https://www.4d4y.com/forum/misc.php?action=swfupload&operation=upload&simple=1&type=image"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "URLError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("https://www.4d4y.com/forum/post.php?action=newthread&fid=\(fid)", forHTTPHeaderField: "Referer")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"uid\"\r\n\r\n\(uid)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"hash\"\r\n\r\n\(hash)\r\n".data(using: .utf8)!)

        let filename = "Hi_\(Int(Date().timeIntervalSince1970)).jpg"
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"Filedata\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

        NetworkManager.shared.session.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data, let responseString = String(data: data, encoding: .utf8) else {
                completion(.failure(NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No data"])))
                return
            }
            print("[NewThread] Upload response: \(responseString)")

            let parts = responseString.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "|")
            if parts.count >= 3, let aid = Int(parts[2]), aid > 0 {
                completion(.success(parts[2]))
                return
            }

            completion(.failure(NSError(domain: "UploadError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse upload response"])))
        }.resume()
    }
}

// MARK: - PHPickerViewControllerDelegate

extension NewThreadViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.selectedImages.append(image)
                        self?.updateAttachmentUI()
                    }
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegate & DataSource

extension NewThreadViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! NewThreadImageCell
        cell.image = selectedImages[indexPath.item]
        cell.deleteCallback = { [weak self] in
            self?.selectedImages.remove(at: indexPath.item)
            self?.updateAttachmentUI()
        }
        return cell
    }
}

// MARK: - NewThreadImageCell

class NewThreadImageCell: UICollectionViewCell {
    let imageView = UIImageView()
    let deleteButton = UIButton(type: .system)
    var deleteCallback: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var image: UIImage? {
        didSet { imageView.image = image }
    }

    private func setupUI() {
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)

        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .white
        deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        deleteButton.layer.cornerRadius = 12
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        contentView.addSubview(deleteButton)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            deleteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            deleteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    @objc private func deleteTapped() { deleteCallback?() }
}
