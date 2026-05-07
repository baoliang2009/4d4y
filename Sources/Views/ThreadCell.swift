import UIKit

class ThreadCell: UITableViewCell {

    static let identifier = "ThreadCell"

    private let containerView = UIView()
    private let avatarImageView = UIImageView()
    private let titleLabel = UILabel()
    private let authorBadge = UIView()
    private let authorLabel = UILabel()
    private let statsContainer = UIView()
    private let replyIcon = UIImageView()
    private let replyLabel = UILabel()
    private let viewIcon = UIImageView()
    private let viewLabel = UILabel()
    private let lastPostLabel = UILabel()
    private let tagView = UIView()
    private let tagLabel = UILabel()

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

        // Container with elevated card effect
        containerView.backgroundColor = Theme.currentCard
        containerView.layer.cornerRadius = Theme.largeRadius
        containerView.layer.borderColor = Theme.currentBorder.cgColor
        containerView.layer.borderWidth = 1

        // Add subtle inner glow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.3
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 12
        containerView.layer.masksToBounds = false

        // Avatar with gradient border ring
        avatarImageView.backgroundColor = Theme.currentMuted
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 22
        avatarImageView.clipsToBounds = true
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = Theme.currentSecondaryText

        // Avatar ring layer
        let avatarRing = CAGradientLayer()
        avatarRing.colors = [
            Theme.primary.cgColor,
            Theme.accent.cgColor
        ]
        avatarRing.startPoint = CGPoint(x: 0, y: 0)
        avatarRing.endPoint = CGPoint(x: 1, y: 1)
        avatarRing.cornerRadius = 24
        avatarImageView.layer.borderWidth = 2
        avatarImageView.layer.borderColor = UIColor.clear.cgColor

        // Title with dynamic type support
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = Theme.currentForeground
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byTruncatingTail

        // Author badge with gradient background
        authorBadge.backgroundColor = Theme.primary.withAlphaComponent(0.15)
        authorBadge.layer.cornerRadius = 6

        authorLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        authorLabel.textColor = Theme.primary

        // Stats container with glass effect
        statsContainer.backgroundColor = Theme.currentSecondary
        statsContainer.layer.cornerRadius = 8

        replyIcon.image = UIImage(systemName: "bubble.left.fill")
        replyIcon.tintColor = Theme.accent
        replyIcon.contentMode = .scaleAspectFit

        replyLabel.font = .systemFont(ofSize: 12, weight: .medium)
        replyLabel.textColor = Theme.currentSecondaryText

        viewIcon.image = UIImage(systemName: "eye.fill")
        viewIcon.tintColor = Theme.currentSecondaryText
        viewIcon.contentMode = .scaleAspectFit

        viewLabel.font = .systemFont(ofSize: 12, weight: .medium)
        viewLabel.textColor = Theme.currentSecondaryText

        // Last post with subtle styling
        lastPostLabel.font = .systemFont(ofSize: 12)
        lastPostLabel.textColor = Theme.currentSecondaryText

        // Tag with vibrant hot color
        tagView.backgroundColor = Theme.hot.withAlphaComponent(0.15)
        tagView.layer.cornerRadius = 6
        tagView.isHidden = true

        tagLabel.font = .systemFont(ofSize: 11, weight: .bold)
        tagLabel.textColor = Theme.hot

        // Observe theme changes
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeDidChange, object: nil)

        contentView.addSubview(containerView)
        containerView.addSubview(avatarImageView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(authorBadge)
        authorBadge.addSubview(authorLabel)
        containerView.addSubview(statsContainer)
        statsContainer.addSubview(replyIcon)
        statsContainer.addSubview(replyLabel)
        statsContainer.addSubview(viewIcon)
        statsContainer.addSubview(viewLabel)
        containerView.addSubview(lastPostLabel)
        containerView.addSubview(tagView)
        tagView.addSubview(tagLabel)

        setupConstraints()
    }

    private func setupConstraints() {
        containerView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        authorBadge.translatesAutoresizingMaskIntoConstraints = false
        authorLabel.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        replyIcon.translatesAutoresizingMaskIntoConstraints = false
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        viewIcon.translatesAutoresizingMaskIntoConstraints = false
        viewLabel.translatesAutoresizingMaskIntoConstraints = false
        lastPostLabel.translatesAutoresizingMaskIntoConstraints = false
        tagView.translatesAutoresizingMaskIntoConstraints = false
        tagLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),

            // Avatar on the left - larger for visual impact
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            avatarImageView.widthAnchor.constraint(equalToConstant: 44),
            avatarImageView.heightAnchor.constraint(equalToConstant: 44),

            // Title in the middle (to the right of avatar)
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),

            // Author badge below title
            authorBadge.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            authorBadge.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            authorLabel.topAnchor.constraint(equalTo: authorBadge.topAnchor, constant: 5),
            authorLabel.leadingAnchor.constraint(equalTo: authorBadge.leadingAnchor, constant: 10),
            authorLabel.trailingAnchor.constraint(equalTo: authorBadge.trailingAnchor, constant: -10),
            authorLabel.bottomAnchor.constraint(equalTo: authorBadge.bottomAnchor, constant: -5),

            // Stats container
            statsContainer.centerYAnchor.constraint(equalTo: authorBadge.centerYAnchor),
            statsContainer.leadingAnchor.constraint(equalTo: authorBadge.trailingAnchor, constant: 12),
            statsContainer.heightAnchor.constraint(equalToConstant: 28),

            replyIcon.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 10),
            replyIcon.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),
            replyIcon.widthAnchor.constraint(equalToConstant: 16),
            replyIcon.heightAnchor.constraint(equalToConstant: 16),

            replyLabel.leadingAnchor.constraint(equalTo: replyIcon.trailingAnchor, constant: 5),
            replyLabel.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),

            viewIcon.leadingAnchor.constraint(equalTo: replyLabel.trailingAnchor, constant: 14),
            viewIcon.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),
            viewIcon.widthAnchor.constraint(equalToConstant: 16),
            viewIcon.heightAnchor.constraint(equalToConstant: 16),

            viewLabel.leadingAnchor.constraint(equalTo: viewIcon.trailingAnchor, constant: 5),
            viewLabel.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),
            viewLabel.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -10),

            lastPostLabel.topAnchor.constraint(equalTo: authorBadge.bottomAnchor, constant: 10),
            lastPostLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            lastPostLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16),

            tagView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            tagView.centerYAnchor.constraint(equalTo: lastPostLabel.centerYAnchor),

            tagLabel.topAnchor.constraint(equalTo: tagView.topAnchor, constant: 4),
            tagLabel.leadingAnchor.constraint(equalTo: tagView.leadingAnchor, constant: 8),
            tagLabel.trailingAnchor.constraint(equalTo: tagView.trailingAnchor, constant: -8),
            tagLabel.bottomAnchor.constraint(equalTo: tagView.bottomAnchor, constant: -4)
        ])
    }

    func configure(with thread: ForumThread) {
        titleLabel.text = thread.title
        authorLabel.text = thread.author
        replyLabel.text = "\(thread.replyCount)"
        viewLabel.text = "\(thread.viewCount)"
        lastPostLabel.text = "最后回复: \(thread.lastPostAuthor) · \(thread.lastPostDate)"

        // Load avatar from URL based on authorUid
        let avatarUrlString = "https://img02.4d4y.com/forum/uc_server/data/avatar/" + formatUidForAvatar(thread.authorUid) + "_avatar_middle.jpg"
        if let avatarUrl = URL(string: avatarUrlString) {
            loadAvatar(from: avatarUrl)
        }

        // Gray out title if thread has been read
        if ReadTracker.shared.isRead(tid: thread.tid) {
            titleLabel.textColor = Theme.currentSecondaryText
        } else {
            titleLabel.textColor = Theme.currentForeground
        }

        // Highlight hot threads
        if thread.replyCount > 50 {
            tagView.isHidden = false
            tagLabel.text = "热帖"
        } else {
            tagView.isHidden = true
        }
    }

    private func formatUidForAvatar(_ uid: Int) -> String {
        // Format: 000/XX/XX/XX for UID like 512300 -> "000/51/23/00"
        let uidString = String(format: "%06d", uid)
        let part1 = String(uidString.prefix(2))
        let part2 = String(uidString.dropFirst(2).prefix(2))
        let part3 = String(uidString.suffix(2))
        return "000/\(part1)/\(part2)/\(part3)"
    }

    private func loadAvatar(from url: URL) {
        URLSession.shared.dataTask(with: url) { [weak self] data, _, error in
            if let data = data, error == nil, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.avatarImageView.image = image
                }
            }
        }.resume()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
    }

    @objc private func themeDidChange() {
        backgroundColor = Theme.currentBackground
        containerView.backgroundColor = Theme.currentCard
        containerView.layer.borderColor = Theme.currentBorder.cgColor
        avatarImageView.backgroundColor = Theme.currentMuted
        avatarImageView.tintColor = Theme.currentSecondaryText
        titleLabel.textColor = Theme.currentForeground
        statsContainer.backgroundColor = Theme.currentSecondary
        replyLabel.textColor = Theme.currentSecondaryText
        viewIcon.tintColor = Theme.currentSecondaryText
        viewLabel.textColor = Theme.currentSecondaryText
        lastPostLabel.textColor = Theme.currentSecondaryText
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        let transform: CGAffineTransform = highlighted ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
        let opacity: Float = highlighted ? 0.8 : 1.0

        if animated {
            UIView.animate(withDuration: Theme.fastAnimation, delay: 0, options: [.curveEaseOut]) {
                self.containerView.transform = transform
                self.containerView.layer.shadowOpacity = opacity
            }
        } else {
            containerView.transform = transform
            containerView.layer.shadowOpacity = opacity
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        setHighlighted(selected, animated: animated)
    }
}
