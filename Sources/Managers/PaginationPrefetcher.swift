import Foundation

/// Coordinates HTML prefetching for thread pages
class PaginationPrefetcher {
    private let tid: Int
    private let networkManager = NetworkManager.shared
    private var pendingPages: [Int: ThreadDetail] = [:]
    private var prefetchingPages: Set<Int> = []
    private var prefetchCallbacks: [Int: [(ThreadDetail?) -> Void]] = [:]

    init(tid: Int) {
        self.tid = tid
    }

    /// Prefetch page N+1 and N+2 after loading current page
    func prefetchNextPages(currentPage: Int, totalPages: Int) {
        guard totalPages > currentPage else { return }

        let nextPage = currentPage + 1
        let pageAfterNext = currentPage + 2

        if nextPage <= totalPages {
            prefetchPage(nextPage)
        }
        if pageAfterNext <= totalPages {
            prefetchPage(pageAfterNext)
        }
    }

    /// Prefetch a specific page
    func prefetchPage(_ page: Int) {
        guard !prefetchingPages.contains(page), pendingPages[page] == nil else { return }

        prefetchingPages.insert(page)

        Task {
            do {
                let detail = try await networkManager.fetchThreadDetailWithoutCache(tid: tid, page: page)
                await MainActor.run {
                    self.pendingPages[page] = detail
                    self.prefetchingPages.remove(page)
                    self.notifyCallbacks(for: page, detail: detail)
                }
            } catch {
                await MainActor.run {
                    self.prefetchingPages.remove(page)
                    self.notifyCallbacks(for: page, detail: nil)
                }
            }
        }
    }

    /// Get prefetched page if available
    func getPrefetchedPage(_ page: Int) -> ThreadDetail? {
        return pendingPages[page]
    }

    /// Clear all prefetched pages
    func clear() {
        pendingPages.removeAll()
        prefetchingPages.removeAll()
        prefetchCallbacks.removeAll()
    }

    private func notifyCallbacks(for page: Int, detail: ThreadDetail?) {
        if let callbacks = prefetchCallbacks[page] {
            callbacks.forEach { $0(detail) }
            prefetchCallbacks[page] = nil
        }
    }
}