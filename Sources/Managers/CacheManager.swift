import Foundation

class CacheManager {
    static let shared = CacheManager()

    private let cacheDirectory: URL
    private let cacheExpiration: TimeInterval = 5 * 60 // 5 minutes cache
    private let maxCacheSize: Int = 50 * 1024 * 1024 // 50MB max cache

    private init() {
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("FourD4YCache", isDirectory: true)

        // Create cache directory if needed
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Save Cache

    func save<T: Encodable>(_ object: T, forKey key: String) {
        let fileURL = cacheFileURL(for: key)

        do {
            let data = try JSONEncoder().encode(object)
            try data.write(to: fileURL)

            // Update metadata
            saveMetadata(forKey: key, data: data)

            print("[Cache] Saved: \(key) (\(data.count) bytes)")
        } catch {
            print("[Cache] Failed to save \(key): \(error)")
        }
    }

    // MARK: - Load Cache

    func load<T: Decodable>(_ type: T.Type, forKey key: String) -> T? {
        let fileURL = cacheFileURL(for: key)

        // Check if file exists
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("[Cache] Not found: \(key)")
            return nil
        }

        // Check if expired
        guard !isExpired(forKey: key) else {
            print("[Cache] Expired: \(key)")
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let object = try JSONDecoder().decode(type, from: data)
            print("[Cache] Loaded: \(key)")
            return object
        } catch {
            print("[Cache] Failed to load \(key): \(error)")
            return nil
        }
    }

    // MARK: - Cache Info

    func isExpired(forKey key: String) -> Bool {
        guard let metadata = loadMetadata(forKey: key),
              let timestamp = metadata["timestamp"] as? TimeInterval else {
            return true
        }

        return Date().timeIntervalSince1970 - timestamp > cacheExpiration
    }

    func getCacheAge(forKey key: String) -> String? {
        guard let metadata = loadMetadata(forKey: key),
              let timestamp = metadata["timestamp"] as? TimeInterval else {
            return nil
        }

        let age = Date().timeIntervalSince1970 - timestamp
        if age < 60 {
            return "\(Int(age)) 秒前"
        } else if age < 3600 {
            return "\(Int(age / 60)) 分钟前"
        } else {
            return "\(Int(age / 3600)) 小时前"
        }
    }

    // MARK: - Clear Cache

    func clearCache(forKey key: String) {
        let fileURL = cacheFileURL(for: key)
        try? FileManager.default.removeItem(at: fileURL)

        let metadataURL = metadataFileURL(for: key)
        try? FileManager.default.removeItem(at: metadataURL)

        print("[Cache] Cleared: \(key)")
    }

    func clearAllCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        print("[Cache] Cleared all cache")
    }

    // MARK: - Private Helpers

    private func cacheFileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent("\(safeKey).json")
    }

    private func metadataFileURL(for key: String) -> URL {
        let safeKey = key.replacingOccurrences(of: "/", with: "_")
        return cacheDirectory.appendingPathComponent("\(safeKey).meta")
    }

    private func saveMetadata(forKey key: String, data: Data) {
        let metadataURL = metadataFileURL(for: key)
        let metadata: [String: Any] = [
            "timestamp": Date().timeIntervalSince1970,
            "size": data.count
        ]

        if let plistData = try? PropertyListSerialization.data(fromPropertyList: metadata, format: .binary, options: 0) {
            try? plistData.write(to: metadataURL)
        }
    }

    private func loadMetadata(forKey key: String) -> [String: Any]? {
        let metadataURL = metadataFileURL(for: key)
        return try? PropertyListSerialization.propertyList(from: Data(contentsOf: metadataURL), format: nil) as? [String: Any]
    }

    // MARK: - Cache Statistics

    func getCacheStats() -> (count: Int, size: String) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return (0, "0 B")
        }

        var totalSize = 0
        var jsonFiles = 0

        for file in files {
            if file.pathExtension == "json" {
                jsonFiles += 1
                if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += size
                }
            }
        }

        let sizeString: String
        if totalSize > 1024 * 1024 {
            sizeString = String(format: "%.1f MB", Double(totalSize) / 1024 / 1024)
        } else if totalSize > 1024 {
            sizeString = String(format: "%.1f KB", Double(totalSize) / 1024)
        } else {
            sizeString = "\(totalSize) B"
        }

        return (jsonFiles, sizeString)
    }
}

// MARK: - Cache Keys

extension CacheManager {
    struct CacheKeys {
        static func forumList() -> String { return "forum_list" }
        static func threadList(fid: Int, page: Int) -> String { return "thread_list_fid\(fid)_page\(page)" }
        static func threadDetail(tid: Int, page: Int) -> String { return "thread_detail_tid\(tid)_page\(page)" }
        static func searchResults(keyword: String, page: Int) -> String { return "search_\(keyword)_page\(page)" }
        static func privateMessages(page: Int) -> String { return "pm_list_page\(page)" }
    }
}
