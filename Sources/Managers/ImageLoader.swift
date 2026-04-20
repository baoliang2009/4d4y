import UIKit
import SDWebImage

/// Configures SDWebImage for optimal image loading performance
class ImageLoader {

    /// Initialize SDWebImage with optimized settings
    static func configure() {
        // Configure image downloader
        let downloader = SDWebImageDownloader.shared
        downloader.config.maxConcurrentDownloads = 6
        downloader.config.downloadTimeout = 30
        downloader.config.executionOrder = .lifoExecutionOrder

        // Configure image cache
        let cache = SDImageCache.shared
        cache.config.maxDiskSize = 500 * 1024 * 1024 // 500 MB disk cache
        cache.config.maxDiskAge = 60 * 60 * 24 * 7 // 1 week
        cache.config.maxMemoryCost = 100 * 1024 * 1024 // 100 MB memory cache
        cache.config.shouldCacheImagesInMemory = true

        // Configure HTTP headers for image requests
        SDWebImageDownloader.shared.setValue("https://www.4d4y.com", forHTTPHeaderField: "Referer")
        SDWebImageDownloader.shared.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        print("[ImageLoader] SDWebImage configured with optimized settings")
    }

    /// Clear all image caches (both memory and disk)
    static func clearCache() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk {
            print("[ImageLoader] Image cache cleared")
        }
    }

    /// Get current cache size
    static func getCacheSize(completion: @escaping (UInt) -> Void) {
        SDImageCache.shared.calculateSize { (fileCount, cacheSize) in
            completion(cacheSize)
        }
    }
}

// MARK: - UIImageView Extension for Better Image Loading

extension UIImageView {

    /// Load image with optimized settings for forum images
    func loadForumImage(
        from urlString: String,
        placeholder: UIImage? = nil,
        completion: ((UIImage?, Error?) -> Void)? = nil
    ) {
        guard let url = URL(string: urlString) else {
            completion?(nil, NSError(domain: "ImageLoader", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }

        let options: SDWebImageOptions = [
            .retryFailed,
            .scaleDownLargeImages
        ]

        sd_setImage(with: url, placeholderImage: placeholder, options: options) { [weak self] image, error, cacheType, imageURL in
            DispatchQueue.main.async {
                if let error = error {
                    print("[ImageLoader] Failed to load image: \(error.localizedDescription)")
                    completion?(nil, error)
                    return
                }

                if let image = image {
                    if cacheType != .none {
                        self?.image = image
                        completion?(image, nil)
                    } else {
                        self?.alpha = 0
                        self?.image = image
                        UIView.animate(withDuration: 0.3) {
                            self?.alpha = 1
                        }
                        completion?(image, nil)
                    }
                }
            }
        }
    }

    /// Cancel current image loading
    func cancelImageLoad() {
        sd_cancelCurrentImageLoad()
    }
}

// MARK: - Full Screen Image Viewer Enhancement

class FullScreenImageViewController: UIViewController {

    private let imageView = UIImageView()
    private let scrollView = UIScrollView()
    private let closeButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let imageURL: String?

    init(image: UIImage) {
        self.imageURL = nil
        super.init(nibName: nil, bundle: nil)
        self.imageView.image = image
    }

    init(imageURL: String) {
        self.imageURL = imageURL
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        if let imageURL = imageURL {
            loadFullImage(from: imageURL)
        }
    }

    private func setupUI() {
        view.backgroundColor = .black

        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)

        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)

        closeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        closeButton.tintColor = .white
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(closeButton)

        setupConstraints()
    }

    private func setupConstraints() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            imageView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),

            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func loadFullImage(from urlString: String) {
        activityIndicator.startAnimating()
        imageView.loadForumImage(from: urlString) { [weak self] image, error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if error != nil {
                    self?.showLoadError(error?.localizedDescription ?? "Unknown error")
                }
            }
        }
    }

    private func showLoadError(_ message: String) {
        let label = UILabel()
        label.text = "图片加载失败\n\(message)"
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        view.addSubview(label)

        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

extension FullScreenImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}
