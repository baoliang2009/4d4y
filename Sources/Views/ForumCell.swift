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
        backgroundColor = Theme.currentBackground
        selectionStyle = .none

        // Icon with gradient background and glow effect
        iconView.backgroundColor = Theme.primary.withAlphaComponent(0.15)
        iconView.tintColor = Theme.primary
        iconView.contentMode = .center
        iconView.layer.cornerRadius = 12

        nameLabel.font = .systemFont(ofSize: 16, weight: .bold)
        nameLabel.textColor = Theme.currentForeground

        descriptionLabel.font = .systemFont(ofSize: 14)
        descriptionLabel.textColor = Theme.currentSecondaryText
        descriptionLabel.numberOfLines = 2

        statsLabel.font = .systemFont(ofSize: 13, weight: .medium)
        statsLabel.textColor = Theme.currentSecondaryText

        // Container card with shadow
        containerView.backgroundColor = Theme.currentCard
        containerView.layer.cornerRadius = Theme.largeRadius
        containerView.layer.borderColor = Theme.currentBorder.cgColor
        containerView.layer.borderWidth = 1
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.2
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 8

        // Observe theme changes
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeDidChange, object: nil)

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
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            iconView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 48),
            iconView.heightAnchor.constraint(equalToConstant: 48),

            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            descriptionLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            descriptionLabel.trailingAnchor.constraint(equalTo: nameLabel.trailingAnchor),

            statsLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8),
            statsLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            statsLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }

    func configure(with forum: Forum) {
        nameLabel.text = forum.name
        descriptionLabel.text = forum.description.isEmpty ? "暂无描述" : forum.description
        statsLabel.text = "主题 \(forum.threadCount) · 帖子 \(forum.postCount)"

        // Set icon based on forum type with varied icons
        let icons = ["bubble.left.and.bubble.right.fill", "person.3.fill", "star.fill", "flame.fill", "leaf.fill", "book.fill", "gamecontroller.fill", "music.note"]
        iconView.image = UIImage(systemName: icons[forum.fid % icons.count])
    }

    @objc private func themeDidChange() {
        backgroundColor = Theme.currentBackground
        containerView.backgroundColor = Theme.currentCard
        containerView.layer.borderColor = Theme.currentBorder.cgColor
        nameLabel.textColor = Theme.currentForeground
        descriptionLabel.textColor = Theme.currentSecondaryText
        statsLabel.textColor = Theme.currentSecondaryText
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let transform: CGAffineTransform = highlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity

        if animated {
            UIView.animate(withDuration: Theme.fastAnimation, delay: 0, options: [.curveEaseOut]) {
                self.containerView.transform = transform
            }
        } else {
            containerView.transform = transform
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        setHighlighted(selected, animated: animated)
    }
}
