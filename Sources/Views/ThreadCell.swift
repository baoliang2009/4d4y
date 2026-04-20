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
        backgroundColor = Theme.background
        selectionStyle = .none

        // Container with subtle shadow
        containerView.backgroundColor = Theme.card
        containerView.layer.cornerRadius = 12
        containerView.layer.borderColor = Theme.border.cgColor
        containerView.layer.borderWidth = 1

        // Avatar
        avatarImageView.backgroundColor = Theme.muted
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.cornerRadius = 20
        avatarImageView.clipsToBounds = true
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = Theme.secondaryText

        // Title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = Theme.titleText
        titleLabel.numberOfLines = 2

        // Author badge
        authorBadge.backgroundColor = Theme.primary.withAlphaComponent(0.15)
        authorBadge.layer.cornerRadius = 4

        authorLabel.font = .systemFont(ofSize: 12, weight: .medium)
        authorLabel.textColor = Theme.primary

        // Stats container
        statsContainer.backgroundColor = Theme.muted
        statsContainer.layer.cornerRadius = 6

        replyIcon.image = UIImage(systemName: "bubble.left")
        replyIcon.tintColor = Theme.secondaryText
        replyIcon.contentMode = .scaleAspectFit

        replyLabel.font = .systemFont(ofSize: 12)
        replyLabel.textColor = Theme.secondaryText

        viewIcon.image = UIImage(systemName: "eye")
        viewIcon.tintColor = Theme.secondaryText
        viewIcon.contentMode = .scaleAspectFit

        viewLabel.font = .systemFont(ofSize: 12)
        viewLabel.textColor = Theme.secondaryText

        // Last post
        lastPostLabel.font = .systemFont(ofSize: 11)
        lastPostLabel.textColor = Theme.secondaryText

        // Tag (hidden by default)
        tagView.backgroundColor = UIColor.systemOrange.withAlphaComponent(0.15)
        tagView.layer.cornerRadius = 4
        tagView.isHidden = true

        tagLabel.font = .systemFont(ofSize: 10, weight: .medium)
        tagLabel.textColor = .systemOrange

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
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // Avatar on the left
            avatarImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 14),
            avatarImageView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),

            // Title in the middle (to the right of avatar)
            titleLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: avatarImageView.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),

            // Author badge below title
            authorBadge.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            authorBadge.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),

            authorLabel.topAnchor.constraint(equalTo: authorBadge.topAnchor, constant: 4),
            authorLabel.leadingAnchor.constraint(equalTo: authorBadge.leadingAnchor, constant: 8),
            authorLabel.trailingAnchor.constraint(equalTo: authorBadge.trailingAnchor, constant: -8),
            authorLabel.bottomAnchor.constraint(equalTo: authorBadge.bottomAnchor, constant: -4),

            // Stats container
            statsContainer.topAnchor.constraint(equalTo: authorBadge.topAnchor),
            statsContainer.leadingAnchor.constraint(equalTo: authorBadge.trailingAnchor, constant: 10),
            statsContainer.heightAnchor.constraint(equalToConstant: 24),

            replyIcon.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 8),
            replyIcon.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),
            replyIcon.widthAnchor.constraint(equalToConstant: 14),
            replyIcon.heightAnchor.constraint(equalToConstant: 14),

            replyLabel.leadingAnchor.constraint(equalTo: replyIcon.trailingAnchor, constant: 4),
            replyLabel.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),

            viewIcon.leadingAnchor.constraint(equalTo: replyLabel.trailingAnchor, constant: 12),
            viewIcon.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),
            viewIcon.widthAnchor.constraint(equalToConstant: 14),
            viewIcon.heightAnchor.constraint(equalToConstant: 14),

            viewLabel.leadingAnchor.constraint(equalTo: viewIcon.trailingAnchor, constant: 4),
            viewLabel.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),
            viewLabel.trailingAnchor.constraint(equalTo: statsContainer.trailingAnchor, constant: -8),

            lastPostLabel.topAnchor.constraint(equalTo: authorBadge.bottomAnchor, constant: 8),
            lastPostLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            lastPostLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -14),

            tagView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -14),
            tagView.centerYAnchor.constraint(equalTo: lastPostLabel.centerYAnchor),

            tagLabel.topAnchor.constraint(equalTo: tagView.topAnchor, constant: 2),
            tagLabel.leadingAnchor.constraint(equalTo: tagView.leadingAnchor, constant: 6),
            tagLabel.trailingAnchor.constraint(equalTo: tagView.trailingAnchor, constant: -6),
            tagLabel.bottomAnchor.constraint(equalTo: tagView.bottomAnchor, constant: -2)
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
            titleLabel.textColor = Theme.secondaryText
        } else {
            titleLabel.textColor = Theme.titleText
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

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        UIView.animate(withDuration: 0.15) {
            self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
        }
    }
}
