import Foundation
import SDWebImage

/// Coordinates image prefetching for thread pages
class ImagePrefetchManager {
    static let shared = ImagePrefetchManager()

    private var prefetchTokens: [Int: [SDWebImagePrefetchToken]] = [:] // tid -> tokens
    private let prefetcher = SDWebImagePrefetcher()

    private init() {
        prefetcher.maxConcurrentPrefetches = 4
    }

    /// Prefetch images for a specific tid
    func prefetchImages(for tid: Int, imageURLs: [String]) {
        let urls = imageURLs.compactMap { URL(string: $0) }
        guard !urls.isEmpty else { return }

        cancelPrefetch(for: tid)

        let token = prefetcher.prefetchURLs(urls)
        prefetchTokens[tid] = [token]
    }

    /// Cancel prefetch for a thread
    func cancelPrefetch(for tid: Int) {
        if let tokens = prefetchTokens[tid] {
            tokens.forEach { $0.cancel() }
            prefetchTokens.removeValue(forKey: tid)
        }
    }

    /// Cancel all prefetches
    func cancelAllPrefetches() {
        prefetchTokens.values.forEach { tokens in
            tokens.forEach { $0.cancel() }
        }
        prefetchTokens.removeAll()
    }
}
