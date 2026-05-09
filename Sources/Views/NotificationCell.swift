import UIKit

class NotificationCell: UITableViewCell {
    static let identifier = "NotificationCell"

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let previewLabel = UILabel()
    private let dateLabel = UILabel()
    private let unreadDot = UIView()

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

        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = Theme.primary

        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = Theme.currentForeground
        titleLabel.numberOfLines = 1

        previewLabel.font = .systemFont(ofSize: 14)
        previewLabel.textColor = Theme.currentSecondaryText
        previewLabel.numberOfLines = 2

        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = Theme.currentSecondaryText
        dateLabel.textAlignment = .right

        unreadDot.backgroundColor = Theme.primary
        unreadDot.layer.cornerRadius = 4
        unreadDot.isHidden = true

        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(previewLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(unreadDot)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        previewLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        unreadDot.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            unreadDot.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: -4),
            unreadDot.topAnchor.constraint(equalTo: iconView.topAnchor, constant: -2),
            unreadDot.widthAnchor.constraint(equalToConstant: 8),
            unreadDot.heightAnchor.constraint(equalToConstant: 8),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: dateLabel.leadingAnchor, constant: -8),

            dateLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            dateLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),

            previewLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            previewLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            previewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            previewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    func configure(with item: NotificationItem) {
        titleLabel.text = item.title
        previewLabel.text = item.preview
        unreadDot.isHidden = item.isRead

        let formatter = RelativeDateTimeFormatter()
        dateLabel.text = formatter.localizedString(for: item.date, relativeTo: Date())

        switch item.type {
        case .reply:
            iconView.image = UIImage(systemName: "bubble.left")
            iconView.tintColor = Theme.primary
        case .pm:
            iconView.image = UIImage(systemName: "envelope")
            iconView.tintColor = Theme.accent
        }
    }
}
