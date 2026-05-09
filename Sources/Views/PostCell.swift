import UIKit
import SDWebImage

protocol PostCellDelegate: AnyObject {
    func postCellDidTapReply(_ cell: PostCell, post: ForumPost)
}

class PostCell: UITableViewCell {

    static let identifier = "PostCell"

    weak var delegate: PostCellDelegate?

    private let containerView = UIView()
    private let avatarView = UIImageView()
    private let authorNameLabel = UILabel()
    private let pinnedBadge = UIView()
    private let pinnedLabel = UILabel()
    private let pinIcon = UIImageView()
    private let dateLabel = UILabel()
    private let floorLabel = UILabel()  // Shows floor number like "1楼"
    private let titleLabel = UILabel()
    let contentLabel = UILabel()  // Internal for ContentFormatter extension
    private let statsContainer = UIView()
    private let replyCountView = UIStackView()
    private let replyIcon = UIImageView()
    private let replyLabel = UILabel()
    private let viewCountView = UIStackView()
    private let viewIcon = UIImageView()
    private let viewLabel = UILabel()
    private let replyButton = UIButton(type: .system)  // Reply button for each post
    private let imagesContainer = UIView()
    private let imagesStackView = UIStackView()

    private var imageViews: [UIImageView] = []
    private var currentPost: ForumPost?
    private var currentImageURLs: [String] = []
    private var filteredImageURLs: [String] = [] // Store filtered URLs without GIFs
    private var contentLabelBottomConstraint: NSLayoutConstraint?
    private var imagesContainerBottomConstraint: NSLayoutConstraint?
    private var imagesContainerTopConstraint: NSLayoutConstraint?
    private var replyButtonTopConstraint: NSLayoutConstraint?
    private var statsContainerHeightConstraint: NSLayoutConstraint?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        selectionStyle = .none
        backgroundColor = Theme.currentBackground

        // Container card with elevated effect
        containerView.backgroundColor = Theme.currentCard
        containerView.layer.cornerRadius = Theme.largeRadius
        containerView.layer.borderColor = Theme.currentBorder.cgColor
        containerView.layer.borderWidth = 1

        // Subtle shadow for depth
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = 0.25
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowRadius = 16
        containerView.layer.masksToBounds = false

        // Avatar with gradient ring
        avatarView.backgroundColor = Theme.currentMuted
        avatarView.contentMode = .scaleAspectFill
        avatarView.layer.cornerRadius = 18
        avatarView.layer.masksToBounds = true
        avatarView.layer.borderColor = Theme.primary.cgColor
        avatarView.layer.borderWidth = 2.5
        avatarView.image = UIImage(systemName: "person.circle.fill")
        avatarView.tintColor = Theme.currentSecondaryText

        // Author name with weight
        authorNameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        authorNameLabel.textColor = Theme.currentForeground

        // Pinned badge with gradient
        pinnedBadge.backgroundColor = Theme.primary.withAlphaComponent(0.15)
        pinnedBadge.layer.cornerRadius = 8

        pinIcon.image = UIImage(systemName: "pin.fill")
        pinIcon.tintColor = Theme.primary
        pinIcon.contentMode = .scaleAspectFit

        pinnedLabel.text = "置顶"
        pinnedLabel.font = .systemFont(ofSize: 12, weight: .bold)
        pinnedLabel.textColor = Theme.primary

        // Date with subtle styling
        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = Theme.currentSecondaryText

        // Floor label with accent
        floorLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        floorLabel.textColor = Theme.accent
        floorLabel.textAlignment = .right

        // Title with emphasis
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = Theme.currentForeground
        titleLabel.numberOfLines = 2

        // Content preview
        contentLabel.font = .systemFont(ofSize: 15, weight: .regular)
        contentLabel.textColor = Theme.currentForeground
        contentLabel.numberOfLines = 0

        // Stats container with glass effect
        statsContainer.backgroundColor = Theme.currentSecondary
        statsContainer.layer.cornerRadius = 10

        replyIcon.image = UIImage(systemName: "message.fill")
        replyIcon.tintColor = Theme.accent
        replyIcon.contentMode = .scaleAspectFit

        replyLabel.font = .systemFont(ofSize: 13, weight: .medium)
        replyLabel.textColor = Theme.currentSecondaryText

        replyCountView.axis = .horizontal
        replyCountView.spacing = 5
        replyCountView.alignment = .center
        replyCountView.addArrangedSubview(replyLabel)

        viewIcon.image = UIImage(systemName: "eye.fill")
        viewIcon.tintColor = Theme.currentSecondaryText
        viewIcon.contentMode = .scaleAspectFit

        viewLabel.font = .systemFont(ofSize: 13, weight: .medium)
        viewLabel.textColor = Theme.currentSecondaryText

        viewCountView.axis = .horizontal
        viewCountView.spacing = 5
        viewCountView.alignment = .center
        viewCountView.addArrangedSubview(viewLabel)

        // Reply button with accent styling
        replyButton.setTitle("回复", for: .normal)
        replyButton.setTitleColor(Theme.primary, for: .normal)
        replyButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        replyButton.backgroundColor = Theme.primary.withAlphaComponent(0.12)
        replyButton.layer.cornerRadius = 8
        replyButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        replyButton.addTarget(self, action: #selector(replyTapped), for: .touchUpInside)
        replyButton.translatesAutoresizingMaskIntoConstraints = false

        // Observe theme changes
        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: .themeDidChange, object: nil)

        // Images container and stack view
        imagesStackView.axis = .vertical
        imagesStackView.spacing = 10
        imagesStackView.distribution = .fill
        imagesContainer.addSubview(imagesStackView)
        imagesContainer.isHidden = true

        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(avatarView)
        containerView.addSubview(authorNameLabel)
        containerView.addSubview(pinnedBadge)
        pinnedBadge.addSubview(pinIcon)
        pinnedBadge.addSubview(pinnedLabel)
        containerView.addSubview(dateLabel)
        containerView.addSubview(floorLabel)
        containerView.addSubview(titleLabel)
        containerView.addSubview(contentLabel)
        containerView.addSubview(statsContainer)
        statsContainer.addSubview(replyCountView)
        statsContainer.addSubview(viewCountView)
        containerView.addSubview(replyButton)
        containerView.addSubview(imagesContainer)

        setupConstraints()
    }

    private func setupConstraints() {
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        authorNameLabel.translatesAutoresizingMaskIntoConstraints = false
        pinnedBadge.translatesAutoresizingMaskIntoConstraints = false
        pinIcon.translatesAutoresizingMaskIntoConstraints = false
        pinnedLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        floorLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentLabel.translatesAutoresizingMaskIntoConstraints = false
        statsContainer.translatesAutoresizingMaskIntoConstraints = false
        replyCountView.translatesAutoresizingMaskIntoConstraints = false
        replyIcon.translatesAutoresizingMaskIntoConstraints = false
        replyLabel.translatesAutoresizingMaskIntoConstraints = false
        viewCountView.translatesAutoresizingMaskIntoConstraints = false
        viewIcon.translatesAutoresizingMaskIntoConstraints = false
        viewLabel.translatesAutoresizingMaskIntoConstraints = false
        replyButton.translatesAutoresizingMaskIntoConstraints = false
        imagesContainer.translatesAutoresizingMaskIntoConstraints = false
        imagesStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Container - 更紧凑的内边距
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            // Avatar - 稍小尺寸，更紧凑
            avatarView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            avatarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            avatarView.widthAnchor.constraint(equalToConstant: 36),
            avatarView.heightAnchor.constraint(equalToConstant: 36),

            // Author name
            authorNameLabel.topAnchor.constraint(equalTo: avatarView.topAnchor, constant: 0),
            authorNameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 10),

            // Floor label (right side) - 更紧凑
            floorLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 12),
            floorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            floorLabel.widthAnchor.constraint(equalToConstant: 45),

            // Pinned badge
            pinnedBadge.centerYAnchor.constraint(equalTo: authorNameLabel.centerYAnchor),
            pinnedBadge.leadingAnchor.constraint(equalTo: authorNameLabel.trailingAnchor, constant: 8),
            pinnedBadge.heightAnchor.constraint(equalToConstant: 22),

            pinIcon.leadingAnchor.constraint(equalTo: pinnedBadge.leadingAnchor, constant: 6),
            pinIcon.centerYAnchor.constraint(equalTo: pinnedBadge.centerYAnchor),
            pinIcon.widthAnchor.constraint(equalToConstant: 12),
            pinIcon.heightAnchor.constraint(equalToConstant: 12),

            pinnedLabel.leadingAnchor.constraint(equalTo: pinIcon.trailingAnchor, constant: 3),
            pinnedLabel.trailingAnchor.constraint(equalTo: pinnedBadge.trailingAnchor, constant: -6),
            pinnedLabel.centerYAnchor.constraint(equalTo: pinnedBadge.centerYAnchor),

            // Date
            dateLabel.topAnchor.constraint(equalTo: authorNameLabel.bottomAnchor, constant: 2),
            dateLabel.leadingAnchor.constraint(equalTo: authorNameLabel.leadingAnchor),

            // Title - 仅楼主贴显示，更紧凑
            titleLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            // Content - 核心内容区域，减少顶部间距
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            contentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            contentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            // Stats container - 仅楼主贴显示，放在内容下方（动态约束）
            statsContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            statsContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            replyCountView.leadingAnchor.constraint(equalTo: statsContainer.leadingAnchor, constant: 8),
            replyCountView.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),

            replyIcon.widthAnchor.constraint(equalToConstant: 14),
            replyIcon.heightAnchor.constraint(equalToConstant: 14),

            viewCountView.leadingAnchor.constraint(equalTo: replyCountView.trailingAnchor, constant: 16),
            viewCountView.centerYAnchor.constraint(equalTo: statsContainer.centerYAnchor),

            viewIcon.widthAnchor.constraint(equalToConstant: 14),
            viewIcon.heightAnchor.constraint(equalToConstant: 14),

            // Images container
            imagesContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            imagesContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),

            // Images stack view fills container
            imagesStackView.topAnchor.constraint(equalTo: imagesContainer.topAnchor),
            imagesStackView.leadingAnchor.constraint(equalTo: imagesContainer.leadingAnchor),
            imagesStackView.trailingAnchor.constraint(equalTo: imagesContainer.trailingAnchor),
            imagesStackView.bottomAnchor.constraint(equalTo: imagesContainer.bottomAnchor),

            // Reply button - 单独一行，位于卡片底部
            // 注意：这里不设置固定的 top 约束，而是在 configure:with: 中动态设置
            replyButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            replyButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -12)
        ])

        // Stats container height — saved as property for dynamic adjustment
        statsContainerHeightConstraint = statsContainer.heightAnchor.constraint(equalToConstant: 28)
        statsContainerHeightConstraint?.isActive = true
    }

    func configure(with post: ForumPost) {
        authorNameLabel.text = post.author
        dateLabel.text = post.postDate

        // Floor label
        floorLabel.text = "#\(post.floorNumber)楼"

        // Title - 仅楼主贴（1楼）显示
        let title = post.title ?? ""
        titleLabel.text = title.isEmpty ? "" : title
        let isFloorOne = post.floorNumber == 1
        titleLabel.isHidden = !isFloorOne || title.isEmpty

        // 清除之前的动态约束
        contentLabelBottomConstraint?.isActive = false
        contentLabelBottomConstraint = nil
        imagesContainerBottomConstraint?.isActive = false
        imagesContainerBottomConstraint = nil
        imagesContainerTopConstraint?.isActive = false
        imagesContainerTopConstraint = nil
        replyButtonTopConstraint?.isActive = false
        replyButtonTopConstraint = nil

        let hasImages = !post.images.isEmpty

        // 回复按钮始终显示
        replyButton.isHidden = false

        // === 统一的约束链：contentLabel → statsContainer → [imagesContainer] → replyButton ===

        // statsContainer 始终在链中，高度动态调整
        statsContainer.isHidden = !isFloorOne
        statsContainerHeightConstraint?.constant = isFloorOne ? 28 : 0

        // contentLabel → statsContainer（始终激活）
        contentLabelBottomConstraint = statsContainer.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 10)
        contentLabelBottomConstraint?.isActive = true

        if isFloorOne {
            replyLabel.text = "\(post.floorNumber)"
            viewLabel.text = "\(post.viewCount)"
        }

        if hasImages {
            // statsContainer → imagesContainer → replyButton
            imagesContainer.isHidden = false
            imagesContainerTopConstraint = imagesContainer.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 10)
            imagesContainerTopConstraint?.isActive = true
            imagesContainerBottomConstraint = imagesContainer.bottomAnchor.constraint(equalTo: replyButton.topAnchor, constant: -10)
            imagesContainerBottomConstraint?.isActive = true
        } else {
            // statsContainer → replyButton（跳过 imagesContainer）
            imagesContainer.isHidden = true
            replyButtonTopConstraint = replyButton.topAnchor.constraint(equalTo: statsContainer.bottomAnchor, constant: 10)
            replyButtonTopConstraint?.isActive = true
        }

        // Content with proper formatting
        let contentText = post.content
        setFormattedContent(contentText)

        // Hide pinned badge by default
        pinnedBadge.isHidden = true

        // Store post for reply action
        currentPost = post

        // Load avatar image
        if let avatarURLString = post.authorAvatar, let avatarURL = URL(string: avatarURLString) {
            avatarView.sd_setImage(with: avatarURL, placeholderImage: UIImage(systemName: "person.circle.fill"))
        } else {
            avatarView.image = UIImage(systemName: "person.circle.fill")
        }

        // Configure images
        configureImages(post.images)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.image = UIImage(systemName: "person.circle.fill")
        // 重置动态约束
        contentLabelBottomConstraint?.isActive = false
        contentLabelBottomConstraint = nil
        imagesContainerBottomConstraint?.isActive = false
        imagesContainerBottomConstraint = nil
        imagesContainerTopConstraint?.isActive = false
        imagesContainerTopConstraint = nil
        replyButtonTopConstraint?.isActive = false
        replyButtonTopConstraint = nil
        // 重置隐藏状态
        statsContainer.isHidden = false
        replyButton.isHidden = false
        imagesContainer.isHidden = true
        titleLabel.isHidden = false
    }

    @objc private func themeDidChange() {
        backgroundColor = Theme.currentBackground
        containerView.backgroundColor = Theme.currentCard
        containerView.layer.borderColor = Theme.currentBorder.cgColor
        avatarView.backgroundColor = Theme.currentMuted
        avatarView.tintColor = Theme.currentSecondaryText
        authorNameLabel.textColor = Theme.currentForeground
        dateLabel.textColor = Theme.currentSecondaryText
        titleLabel.textColor = Theme.currentForeground
        contentLabel.textColor = Theme.currentForeground
        statsContainer.backgroundColor = Theme.currentSecondary
        replyLabel.textColor = Theme.currentSecondaryText
        viewIcon.tintColor = Theme.currentSecondaryText
        viewLabel.textColor = Theme.currentSecondaryText
    }

    func configure(with thread: ForumThread) {
        authorNameLabel.text = thread.author
        dateLabel.text = thread.lastPostDate
        titleLabel.text = thread.title
        titleLabel.isHidden = false

        replyLabel.text = "\(thread.replyCount)"
        viewLabel.text = "\(thread.viewCount)"

        avatarView.image = UIImage(systemName: "person.circle.fill")
        pinnedBadge.isHidden = true

        configureImages([])
    }

    private func configureImages(_ imageURLs: [String]) {
        // Remove existing image views
        for imgView in imageViews {
            imgView.removeFromSuperview()
        }
        imageViews.removeAll()
        currentImageURLs = imageURLs

        // Remove existing arranged subviews
        for view in imagesStackView.arrangedSubviews {
            imagesStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        // Filter out GIF images and deduplicate
        let uniqueURLs = Array(Set(imageURLs))
        filteredImageURLs = uniqueURLs

        if uniqueURLs.isEmpty {
            imagesContainer.isHidden = true
            return
        }

        imagesContainer.isHidden = false

        for (index, imageURL) in uniqueURLs.prefix(3).enumerated() {
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = Theme.currentMuted
            imageView.layer.cornerRadius = 8
            imageView.clipsToBounds = true
            imageView.isUserInteractionEnabled = true
            imageView.tag = index

            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
            imageView.addGestureRecognizer(tapGesture)

            imageView.translatesAutoresizingMaskIntoConstraints = false

            // Fixed height for images
            imageView.heightAnchor.constraint(equalToConstant: 180).isActive = true

            // Use optimized image loading with progress indicator
            imageView.loadForumImage(from: imageURL, placeholder: nil) { [weak imageView] image, error in
                if error != nil {
                    // Show placeholder on error
                    imageView?.backgroundColor = Theme.currentMuted
                }
            }

            imagesStackView.addArrangedSubview(imageView)
            imageViews.append(imageView)
        }
    }

    @objc private func replyTapped() {
        guard let post = currentPost else { return }
        delegate?.postCellDidTapReply(self, post: post)
    }

    @objc private func imageTapped(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        let tappedIndex = imageView.tag

        // Use filteredImageURLs since it excludes GIFs
        if tappedIndex < filteredImageURLs.count {
            let imageURL = filteredImageURLs[tappedIndex]
            showFullScreenImage(withURL: imageURL, placeholder: imageView.image)
        } else if let image = imageView.image {
            // Fallback to thumbnail
            showFullScreenImage(image)
        }
    }

    private func showFullScreenImage(withURL url: String, placeholder: UIImage?) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let fullScreenVC = FullScreenImageViewController(imageURL: url)
        fullScreenVC.modalPresentationStyle = .fullScreen
        window.rootViewController?.present(fullScreenVC, animated: true)
    }

    private func showFullScreenImage(_ image: UIImage) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let fullScreenVC = FullScreenImageViewController(image: image)
        fullScreenVC.modalPresentationStyle = .fullScreen
        window.rootViewController?.present(fullScreenVC, animated: true)
    }
}
