import UIKit
import SDWebImage

class PMCell: UITableViewCell {

    static let identifier = "PMCell"

    private let containerView = UIView()
    private let avatarImageView = UIImageView()
    private let usernameLabel = UILabel()
    private let dateLabel = UILabel()
    private let subjectLabel = UILabel()
    private let summaryLabel = UILabel()
    private let newIndicator = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none

        containerView.backgroundColor = Theme.currentCard
        containerView.layer.cornerRadius = 12
        contentView.addSubview(containerView)

        avatarImageView.backgroundColor = Theme.currentMuted
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 24
        avatarImageView.clipsToBounds = true
        avatarImageView.tintColor = Theme.currentSecondaryText
        containerView.addSubview(avatarImageView)

        usernameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        usernameLabel.textColor = Theme.currentForeground
        containerView.addSubview(usernameLabel)

        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = Theme.currentSecondaryText
        dateLabel.textAlignment = .right
        containerView.addSubview(dateLabel)

        subjectLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subjectLabel.textColor = Theme.currentForeground
        subjectLabel.numberOfLines = 1
        containerView.addSubview(subjectLabel)

        summaryLabel.font = .systemFont(ofSize: 12)
        summaryLabel.textColor = Theme.currentSecondaryText
        summaryLabel.numberOfLines = 2
        containerView.addSubview(summaryLabel)

        newIndicator.backgroundColor = Theme.primary
        newIndicator.layer.cornerRadius = 4
        newIndicator.isHidden = true
        containerView.addSubview(newIndicator)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        usernameLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        subjectLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        newIndicator.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            avatarImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 48),
            avatarImageView.heightAnchor.constraint(equalToConstant: 48),

            usernameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            usernameLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),

            dateLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            dateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: usernameLabel.trailingAnchor, constant: 8),

            subjectLabel.topAnchor.constraint(equalTo: usernameLabel.bottomAnchor, constant: 4),
            subjectLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            subjectLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            summaryLabel.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 2),
            summaryLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            summaryLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            newIndicator.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            newIndicator.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 4),
            newIndicator.widthAnchor.constraint(equalToConstant: 8),
            newIndicator.heightAnchor.constraint(equalToConstant: 8)
        ])
    }

    func configure(with pm: PrivateMessage) {
        usernameLabel.text = pm.fromUsername
        dateLabel.text = pm.messageDate
        subjectLabel.text = pm.subject
        summaryLabel.text = pm.summary
        newIndicator.isHidden = !pm.isNew

        if let avatarURL = pm.fromAvatar, !avatarURL.isEmpty {
            if avatarURL.hasPrefix("http") {
                avatarImageView.sd_setImage(with: URL(string: avatarURL), placeholderImage: UIImage(systemName: "person.circle.fill"))
            } else {
                avatarImageView.image = UIImage(systemName: "person.circle.fill")
            }
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
        }

        // Gray out if not new
        if pm.isNew {
            containerView.alpha = 1.0
        } else {
            containerView.alpha = 0.7
        }
    }
}
