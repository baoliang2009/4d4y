import UIKit

/// A custom bottom sheet picker for selecting options
/// Provides a better visual experience than UIAlertController actionSheet
class SelectionPickerView: UIView {

    // MARK: - Properties

    private let options: [(id: Int, name: String)]
    private var onSelect: ((Int, String) -> Void)?

    private let containerView = UIView()
    private let titleLabel = UILabel()
    private let tableView = UITableView()
    private let cancelButton = UIButton(type: .system)
    private let dimView = UIView()

    private let maxVisibleRows = 5
    private var rowHeight: CGFloat = 52

    // MARK: - Init

    init(title: String, options: [(id: Int, name: String)], selectedId: Int? = nil, onSelect: @escaping (Int, String) -> Void) {
        self.options = options
        self.onSelect = onSelect
        super.init(frame: .zero)

        setupUI(title: title)
        preselectRow(for: selectedId)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(title: String) {
        // Self setup
        backgroundColor = .clear
        frame = UIScreen.main.bounds

        // Dim view (background overlay)
        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        dimView.alpha = 0
        addSubview(dimView)
        dimView.frame = bounds

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dimViewTapped))
        dimView.addGestureRecognizer(tapGesture)

        // Calculate container height
        let visibleRows = min(options.count, maxVisibleRows)
        let tableHeight = CGFloat(visibleRows) * rowHeight
        let headerHeight: CGFloat = 56
        let bottomSafeArea: CGFloat = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets.bottom ?? 20

        let containerHeight = headerHeight + tableHeight + bottomSafeArea

        // Container view
        containerView.backgroundColor = Theme.currentBackground
        containerView.layer.cornerRadius = 16
        containerView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: -4)
        containerView.layer.shadowRadius = 12
        containerView.layer.shadowOpacity = 0.15
        containerView.clipsToBounds = false
        addSubview(containerView)

        // Title label
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = Theme.currentForeground
        titleLabel.textAlignment = .center
        containerView.addSubview(titleLabel)

        // Table view
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = Theme.currentBorder
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        tableView.rowHeight = rowHeight
        tableView.isScrollEnabled = options.count > maxVisibleRows
        tableView.register(SelectionCell.self, forCellReuseIdentifier: "SelectionCell")
        tableView.dataSource = self
        tableView.delegate = self
        containerView.addSubview(tableView)

        // Cancel button
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        cancelButton.setTitleColor(Theme.primary, for: .normal)
        cancelButton.backgroundColor = Theme.currentMuted
        cancelButton.layer.cornerRadius = 12
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        containerView.addSubview(cancelButton)

        // Layout
        dimView.frame = bounds

        containerView.frame = CGRect(
            x: 0,
            y: bounds.height,
            width: bounds.width,
            height: containerHeight
        )

        titleLabel.frame = CGRect(x: 20, y: 12, width: bounds.width - 40, height: 32)

        tableView.frame = CGRect(
            x: 0,
            y: headerHeight,
            width: bounds.width,
            height: tableHeight
        )

        let buttonMargin: CGFloat = 16
        let buttonHeight: CGFloat = 50
        cancelButton.frame = CGRect(
            x: buttonMargin,
            y: headerHeight + tableHeight + 8,
            width: bounds.width - buttonMargin * 2,
            height: buttonHeight
        )
    }

    private func preselectRow(for id: Int?) {
        guard let id = id else { return }
        if let index = options.firstIndex(where: { $0.id == id }) {
            tableView.selectRow(at: IndexPath(row: index, section: 0), animated: false, scrollPosition: .none)
        }
    }

    // MARK: - Animation

    func show(in view: UIView? = nil) {
        let targetView = view ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first

        guard let container = targetView else { return }

        container.addSubview(self)

        // Animate in
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.5) {
            self.dimView.alpha = 1
            self.containerView.frame.origin.y = self.bounds.height - self.containerView.frame.height
        }
    }

    func dismiss(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseOut) {
            self.dimView.alpha = 0
            self.containerView.frame.origin.y = self.bounds.height
        } completion: { _ in
            self.onSelect = nil
            self.removeFromSuperview()
            completion?()
        }
    }

    // MARK: - Actions

    @objc private func dimViewTapped() {
        dismiss()
    }

    @objc private func cancelTapped() {
        dismiss()
    }
}

// MARK: - UITableViewDataSource & Delegate

extension SelectionPickerView: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SelectionCell", for: indexPath) as! SelectionCell
        let option = options[indexPath.row]
        cell.configure(name: option.name, isSelected: tableView.indexPathForSelectedRow?.row == indexPath.row)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let option = options[indexPath.row]

        // Reload to update checkmark
        tableView.reloadRows(at: [indexPath], with: .none)

        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // Callback after brief delay for visual feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            self?.onSelect?(option.id, option.name)
            self?.dismiss()
        }
    }
}

// MARK: - SelectionCell

private class SelectionCell: UITableViewCell {

    private let nameLabel = UILabel()
    private let checkmarkImageView = UIImageView()

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

        // Name label
        nameLabel.font = .systemFont(ofSize: 17)
        nameLabel.textColor = Theme.currentForeground
        contentView.addSubview(nameLabel)

        // Checkmark
        checkmarkImageView.image = UIImage(systemName: "checkmark")
        checkmarkImageView.tintColor = Theme.primary
        checkmarkImageView.contentMode = .scaleAspectFit
        checkmarkImageView.isHidden = true
        contentView.addSubview(checkmarkImageView)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        checkmarkImageView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: checkmarkImageView.leadingAnchor, constant: -12),

            checkmarkImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            checkmarkImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkImageView.widthAnchor.constraint(equalToConstant: 20),
            checkmarkImageView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }

    func configure(name: String, isSelected: Bool) {
        nameLabel.text = name
        checkmarkImageView.isHidden = !isSelected

        if isSelected {
            nameLabel.textColor = Theme.primary
            nameLabel.font = .systemFont(ofSize: 17, weight: .medium)
        } else {
            nameLabel.textColor = Theme.currentForeground
            nameLabel.font = .systemFont(ofSize: 17)
        }
    }
}
