import Foundation

actor AccessStore {
    static let shared = AccessStore()

    struct Folder: Codable, Identifiable, Sendable, Equatable {
        let name: String
        let bookmark: Data

        var id: Data { bookmark }
    }

    #if os(macOS)
    private static let creationOptions: URL.BookmarkCreationOptions = [.withSecurityScope]
    private static let resolutionOptions: URL.BookmarkResolutionOptions = [.withSecurityScope, .withoutUI]
    #else
    private static let creationOptions: URL.BookmarkCreationOptions = []
    private static let resolutionOptions: URL.BookmarkResolutionOptions = []
    #endif

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
        let bookmark = try url.bookmarkData(options: Self.creationOptions)
        folders.removeAll { folder in
            var stale = false
            let savedURL = try? URL(resolvingBookmarkData: folder.bookmark, options: Self.resolutionOptions, relativeTo: nil, bookmarkDataIsStale: &stale)
            return savedURL?.standardizedFileURL == url.standardizedFileURL
        }
        folders.append(Folder(name: name, bookmark: bookmark))
        persist()
    }

    func remove(name: String) {
        folders.removeAll { $0.name == name }
        persist()
    }

    func url(for folder: Folder) throws -> URL {
        var stale = false
        let url = try URL(resolvingBookmarkData: folder.bookmark, options: Self.resolutionOptions, relativeTo: nil, bookmarkDataIsStale: &stale)
        if stale {
            let lease = FolderAccessLease(url: url)
            defer { withExtendedLifetime(lease) {} }
            let refreshed = try url.bookmarkData(options: Self.creationOptions)
            folders = folders.map { $0.id == folder.id ? Folder(name: $0.name, bookmark: refreshed) : $0 }
            persist()
        }
        return url
    }

    private func persist() {
        defaults.set(try? JSONEncoder().encode(folders), forKey: storageKey)
    }
}
