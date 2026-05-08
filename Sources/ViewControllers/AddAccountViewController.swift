import UIKit

protocol AddAccountViewControllerDelegate: AnyObject {
    func addAccountViewControllerDidAddAccount(_ controller: AddAccountViewController)
}

class AddAccountViewController: UIViewController {
    weak var delegate: AddAccountViewControllerDelegate?

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let questionPicker = UIPickerView()
    private let answerField = UITextField()
    private let errorLabel = UILabel()
    private let loginButton = UIButton(type: .system)

    private let questions = ["无", "安全提问(未设置)", "母亲的名字", "父亲的职业", "座右铭", "最喜欢的电影", "最喜欢的歌曲", "最熟悉的童年回忆"]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigation()
    }

    private func setupNavigation() {
        title = "添加账号"
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelTapped))
    }

    private func setupUI() {
        view.backgroundColor = Theme.currentBackground

        // ScrollView
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

        // Username field
        usernameField.placeholder = "用户名"
        usernameField.borderStyle = .roundedRect
        usernameField.backgroundColor = Theme.currentCard
        usernameField.textColor = Theme.currentForeground
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no

        // Password field
        passwordField.placeholder = "密码"
        passwordField.borderStyle = .roundedRect
        passwordField.backgroundColor = Theme.currentCard
        passwordField.textColor = Theme.currentForeground
        passwordField.isSecureTextEntry = true

        // Question picker
        questionPicker.delegate = self
        questionPicker.dataSource = self
        questionPicker.backgroundColor = Theme.currentCard

        // Answer field
        answerField.placeholder = "安全问题答案"
        answerField.borderStyle = .roundedRect
        answerField.backgroundColor = Theme.currentCard
        answerField.textColor = Theme.currentForeground

        // Error label
        errorLabel.font = .systemFont(ofSize: 14)
        errorLabel.textColor = .systemRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        // Login button
        loginButton.setTitle("登录", for: .normal)
        loginButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        loginButton.backgroundColor = Theme.primary
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 10
        loginButton.addTarget(self, action: #selector(loginTapped), for: .touchUpInside)

        // Labels
        let usernameLabel = UILabel()
        usernameLabel.text = "用户名"
        usernameLabel.font = .systemFont(ofSize: 14, weight: .medium)
        usernameLabel.textColor = Theme.currentSecondaryText

        let passwordLabel = UILabel()
        passwordLabel.text = "密码"
        passwordLabel.font = .systemFont(ofSize: 14, weight: .medium)
        passwordLabel.textColor = Theme.currentSecondaryText

        let questionLabel = UILabel()
        questionLabel.text = "安全问题"
        questionLabel.font = .systemFont(ofSize: 14, weight: .medium)
        questionLabel.textColor = Theme.currentSecondaryText

        let answerLabel = UILabel()
        answerLabel.text = "答案"
        answerLabel.font = .systemFont(ofSize: 14, weight: .medium)
        answerLabel.textColor = Theme.currentSecondaryText

        // Add subviews
        contentView.addSubview(usernameLabel)
        contentView.addSubview(usernameField)
        contentView.addSubview(passwordLabel)
        contentView.addSubview(passwordField)
        contentView.addSubview(questionLabel)
        contentView.addSubview(questionPicker)
        contentView.addSubview(answerLabel)
        contentView.addSubview(answerField)
        contentView.addSubview(errorLabel)
        contentView.addSubview(loginButton)

        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        usernameField.translatesAutoresizingMaskIntoConstraints = false
        passwordLabel.translatesAutoresizingMaskIntoConstraints = false
        passwordField.translatesAutoresizingMaskIntoConstraints = false
        questionLabel.translatesAutoresizingMaskIntoConstraints = false
        questionPicker.translatesAutoresizingMaskIntoConstraints = false
        answerLabel.translatesAutoresizingMaskIntoConstraints = false
        answerField.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        loginButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            usernameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            usernameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            usernameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            usernameField.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 8),
            usernameField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            usernameField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            usernameField.heightAnchor.constraint(equalToConstant: 44),

            passwordLabel.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 16),
            passwordLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            passwordLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            passwordField.topAnchor.constraint(equalTo: passwordLabel.bottomAnchor, constant: 8),
            passwordField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            passwordField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            passwordField.heightAnchor.constraint(equalToConstant: 44),

            questionLabel.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 16),
            questionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            questionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            questionPicker.topAnchor.constraint(equalTo: questionLabel.bottomAnchor, constant: 8),
            questionPicker.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            questionPicker.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            questionPicker.heightAnchor.constraint(equalToConstant: 120),

            answerLabel.topAnchor.constraint(equalTo: questionPicker.bottomAnchor, constant: 16),
            answerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            answerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            answerField.topAnchor.constraint(equalTo: answerLabel.bottomAnchor, constant: 8),
            answerField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            answerField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            answerField.heightAnchor.constraint(equalToConstant: 44),

            errorLabel.topAnchor.constraint(equalTo: answerField.bottomAnchor, constant: 16),
            errorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            errorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            loginButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 24),
            loginButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            loginButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            loginButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -40)
        ])
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func loginTapped() {
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showError("请填写用户名和密码")
            return
        }

        let questionId = questionPicker.selectedRow(inComponent: 0)
        let answer = answerField.text ?? ""

        loginButton.isEnabled = false
        loginButton.setTitle("登录中...", for: .normal)

        Task {
            do {
                // First save to AccountManager
                _ = try AccountManager.shared.addAccount(
                    username: username,
                    password: password,
                    questionId: questionId,
                    answer: answer,
                    uid: 0
                )

                // Then perform login
                let success = try await NetworkManager.shared.login(
                    username: username,
                    password: password,
                    questionId: questionId,
                    answer: answer
                )

                await MainActor.run {
                    if success {
                        delegate?.addAccountViewControllerDidAddAccount(self)
                        dismiss(animated: true)
                    } else {
                        showError("登录失败，请检查用户名和密码")
                        loginButton.isEnabled = true
                        loginButton.setTitle("登录", for: .normal)
                    }
                }
            } catch {
                await MainActor.run {
                    showError(error.localizedDescription)
                    loginButton.isEnabled = true
                    loginButton.setTitle("登录", for: .normal)
                }
            }
        }
    }

    private func showError(_ message: String) {
        errorLabel.text = message
        errorLabel.isHidden = false
    }
}

// MARK: - UIPickerViewDataSource

extension AddAccountViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return questions.count
    }
}

// MARK: - UIPickerViewDelegate

extension AddAccountViewController: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return questions[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        answerField.isHidden = (row == 0)
    }
}