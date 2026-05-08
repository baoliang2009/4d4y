import UIKit

class AccountCell: UITableViewCell {
    static let identifier = "AccountCell"

    private let avatarView = UIImageView()
    private let usernameLabel = UILabel()
    private let currentBadge = UILabel()
    private let checkmarkView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Theme.currentCard
        selectionStyle = .none

        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 18
        avatarView.clipsToBounds = true
        avatarView.backgroundColor = Theme.currentMuted
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = Theme.currentSecondaryText

        usernameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        usernameLabel.textColor = Theme.currentForeground

        currentBadge.text = "当前"
        currentBadge.font = .systemFont(ofSize: 11, weight: .semibold)
        currentBadge.textColor = .white
        currentBadge.backgroundColor = Theme.primary
        currentBadge.layer.cornerRadius = 8
        currentBadge.clipsToBounds = true
        currentBadge.textAlignment = .center
        currentBadge.isHidden = true

        checkmarkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkView.tintColor = Theme.primary
        checkmarkView.contentMode = .scaleAspectFit
        checkmarkView.isHidden = true

        contentView.addSubview(avatarView)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(currentBadge)
        contentView.addSubview(checkmarkView)

        avatarView.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        currentBadge.translatesAutoresizingMaskIntoConstraints = false
        checkmarkView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            avatarView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: 36),
            avatarView.heightAnchor.constraint(equalToConstant: 36),

            usernameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            usernameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            currentBadge.leadingAnchor.constraint(equalTo: usernameLabel.trailingAnchor, constant: 8),
            currentBadge.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            currentBadge.widthAnchor.constraint(equalToConstant: 36),
            currentBadge.heightAnchor.constraint(equalToConstant: 18),

            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }

    func configure(with account: Account, isCurrent: Bool) {
        usernameLabel.text = account.username
        currentBadge.isHidden = !isCurrent
        checkmarkView.isHidden = !isCurrent

        if isCurrent {
            usernameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        } else {
            usernameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        }
    }
}
