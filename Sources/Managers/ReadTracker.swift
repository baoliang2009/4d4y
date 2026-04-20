import Foundation

class ReadTracker {
    static let shared = ReadTracker()

    private let userDefaults = UserDefaults.standard
    private let readThreadsKey = "readThreadIds"

    private var readThreadIds: Set<Int> {
        get {
            let array = userDefaults.array(forKey: readThreadsKey) as? [Int] ?? []
            return Set(array)
        }
        set {
            userDefaults.set(Array(newValue), forKey: readThreadsKey)
        }
    }

    private init() {}

    func markAsRead(tid: Int) {
        var ids = readThreadIds
        ids.insert(tid)
        readThreadIds = ids
    }

    func isRead(tid: Int) -> Bool {
        return readThreadIds.contains(tid)
    }

    func clearAll() {
        readThreadIds = []
    }
}
