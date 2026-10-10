import Foundation

actor AccessStore {
    static let shared = AccessStore()

    struct Folder: Codable, Identifiable, Sendable, Equatable {
        let name: String
        let bookmark: Data

        var id: Data { bookmark }
    }

    private let defaults: UserDefaults
    private let storageKey = "daisyiOS.scanned-folders"
    private(set) var folders: [Folder]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([Folder].self, from: data) {
            self.folders = saved
        } else {
            self.folders = []
        }
    }

    func add(name: String, url: URL) throws {
        let bookmark = try url.bookmarkData()
        folders.removeAll { $0.name == name }
        folders.append(Folder(name: name, bookmark: bookmark))
        persist()
    }

    func remove(name: String) {
        folders.removeAll { $0.name == name }
        persist()
    }

    func url(for folder: Folder) throws -> URL {
        var stale = false
        let url = try URL(resolvingBookmarkData: folder.bookmark, relativeTo: nil, bookmarkDataIsStale: &stale)
        if stale {
            let refreshed = try url.bookmarkData()
            folders = folders.map { $0.id == folder.id ? Folder(name: $0.name, bookmark: refreshed) : $0 }
            persist()
        }
        return url
    }

    private func persist() {
        defaults.set(try? JSONEncoder().encode(folders), forKey: storageKey)
    }
}
