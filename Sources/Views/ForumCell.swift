import UIKit

class ForumCell: UITableViewCell {

    static let identifier = "ForumCell"

    private let containerView = UIView()
    private let nameLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let statsLabel = UILabel()
    private let iconView = UIImageView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = Theme.background
        selectionStyle = .none

        // Icon with gradient background
        iconView.backgroundColor = Theme.primary.withAlphaComponent(0.15)
        iconView.tintColor = Theme.primary
        iconView.contentMode = .center
        iconView.layer.cornerRadius = 8

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = Theme.titleText

        descriptionLabel.font = .systemFont(ofSize: 13)
        descriptionLabel.textColor = Theme.secondaryText
        descriptionLabel.numberOfLines = 2

        statsLabel.font = .systemFont(ofSize: 12)
        statsLabel.textColor = Theme.secondaryText

        containerView.backgroundColor = Theme.card
        containerView.layer.cornerRadius = 12
        containerView.layer.borderColor = Theme.border.cgColor
        containerView.layer.borderWidth = 1

        contentView.addSubview(containerView)
        containerView.addSubview(iconView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(descriptionLabel)
        containerView.addSubview(statsLabel)

        containerView.translatesAutoresizingMaskIntoConstraints = false
        iconView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        statsLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),

            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),

            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            statsLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 6),
            statsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14)
        ])
    }

    func configure(with forum: Forum) {
        nameLabel.text = forum.name
        descriptionLabel.text = forum.description.isEmpty ? "暂无描述" : forum.description
        statsLabel.text = "主题 \(forum.threadCount) · 帖子 \(forum.postCount)"

        // Set icon based on forum type
        iconView.image = UIImage(systemName: "bubble.left.and.bubble.right.fill")
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
        }
    }
}
