import Foundation
import Observation

@MainActor @Observable
final class ScanResult {
    private(set) var root: FileNode
    let isAppContainer: Bool
    let unreadableEntries: Int
    let accessLease: FolderAccessLease?
    var isDeleting = false
    var deletionProgress = 0
    var errorMessage: String?

    init(root: FileNode, isAppContainer: Bool, accessLease: FolderAccessLease? = nil, unreadableEntries: Int = 0) {
        self.unreadableEntries = unreadableEntries
        self.root = root
        self.isAppContainer = isAppContainer
        self.accessLease = accessLease
    }
    func find(_ url: URL) -> FileNode? { root.find(url) }
    func canDelete(_ node: FileNode) -> Bool {
        FileDeletionService.isAllowed(node.url, root: root.url, isAppContainer: isAppContainer)
    }
    func deleteNodes(_ nodes: [FileNode]) async -> (removed: Set<String>, failed: Int, stopped: Bool) {
        guard !isDeleting else { return ([], nodes.count, false) }
        isDeleting = true
        deletionProgress = 0
        defer { isDeleting = false }
        let plan = await Task.detached { DeletionSelection.minimalRoots(nodes) }.value
        let service = FileDeletionService()
        var removed: Set<String> = []
        var failed = 0
        var lastUpdate = Date.distantPast
        for (index, node) in plan.enumerated() {
            if Task.isCancelled { break }
            do {
                try await service.remove(node.url, root: root.url, isAppContainer: isAppContainer)
                removed.insert(node.url.standardizedFileURL.path)
            } catch { failed += 1; errorMessage = error.localizedDescription }
            if Date().timeIntervalSince(lastUpdate) > 0.15 { deletionProgress = index + 1; lastUpdate = Date() }
        }
        let snapshot = root
        let paths = removed
        root = await Task.detached {
            var updated = snapshot
            updated.removeDescendants(paths: paths)
            return updated
        }.value
        return (removed, failed, Task.isCancelled)
    }
    func deleteDuplicateGroup(_ files: [DuplicateFile], keeping keep: DuplicateFile, hash: String) async -> (removed: Set<String>, failed: Int, stopped: Bool) {
        guard !isDeleting else { return ([], files.count, false) }
        isDeleting = true
        deletionProgress = 0
        defer { isDeleting = false }
        var removed: Set<String> = []
        var failed = 0
        let service = FileDeletionService()
        var lastUpdate = Date.distantPast
        for (index, file) in files.enumerated() {
            if Task.isCancelled { break }
            do {
                try await service.removeDuplicate(file, keeping: keep, hash: hash, root: root.url, isAppContainer: isAppContainer)
                removed.insert(file.id)
            } catch {
                if !Task.isCancelled { failed += 1; errorMessage = error.localizedDescription }
            }
            if Date().timeIntervalSince(lastUpdate) > 0.15 {
                deletionProgress = index + 1
                lastUpdate = Date()
            }
        }
        let snapshot = root
        let deletedPaths = removed
        root = await Task.detached {
            var updated = snapshot
            updated.removeDescendants(paths: deletedPaths)
            return updated
        }.value
        return (removed, failed, Task.isCancelled)
    }
    func delete(_ node: FileNode) async -> Bool {
        guard !isDeleting else { return false }
        isDeleting = true
        defer { isDeleting = false }
        do {
            try await FileDeletionService().remove(node.url, root: root.url, isAppContainer: isAppContainer)
            root.removeDescendant(node.url)
            return true
        } catch {
            errorMessage = "Löschen fehlgeschlagen. " + error.localizedDescription
            return false
        }
    }
}

extension FileNode {
    func find(_ target: URL) -> FileNode? {
        let expected = target.standardizedFileURL
        let components = expected.pathComponents
        if url.standardizedFileURL.pathComponents == components { return self }
        for child in children {
            let childURL = child.url.standardizedFileURL
            if childURL.pathComponents == components { return child }
            if child.isDirectory, components.starts(with: childURL.pathComponents) {
                return child.find(expected)
            }
        }
        return nil
    }
    mutating func removeDescendants(paths: Set<String>) {
        children.removeAll { paths.contains($0.url.path) }
        for index in children.indices where children[index].isDirectory { children[index].removeDescendants(paths: paths) }
        if isDirectory {
            aggregateSize = size + children.reduce(0) { $0 + $1.aggregateSize }
            fileCount = children.reduce(0) { $0 + $1.fileCount }
            directoryCount = 1 + children.reduce(0) { $0 + $1.directoryCount }
        }
    }
    mutating func removeDescendant(_ target: URL) {
        children.removeAll { $0.url.standardizedFileURL == target.standardizedFileURL }
        for index in children.indices { children[index].removeDescendant(target) }
        if isDirectory {
            aggregateSize = size + children.reduce(0) { $0 + $1.aggregateSize }
            fileCount = children.reduce(0) { $0 + $1.fileCount }
            directoryCount = 1 + children.reduce(0) { $0 + $1.directoryCount }
        }
    }
}

actor FileDeletionService {
    enum DeletionError: LocalizedError {
        case protectedLocation
        var errorDescription: String? { "Dieser Ort ist geschützt. Der Analyseordner selbst und interne App-Einstellungen können nicht gelöscht werden." }
    }
    nonisolated static func isAllowed(_ url: URL, root: URL, isAppContainer: Bool) -> Bool {
        let target = url.standardizedFileURL.resolvingSymlinksInPath()
        let base = root.standardizedFileURL.resolvingSymlinksInPath()
        guard isDescendant(target, of: base) else { return false }
        if isAppContainer {
            return ["Documents", "Library/Caches", "tmp"].contains { path in
                let writable = base.appending(path: path).standardizedFileURL
                return target == writable || isDescendant(target, of: writable)
            }
        }
        return true
    }
    nonisolated private static func isDescendant(_ url: URL, of base: URL) -> Bool {
        let parts = url.pathComponents
        let parent = base.pathComponents
        return parts.count > parent.count && Array(parts.prefix(parent.count)) == parent
    }
    func removeDuplicate(_ file: DuplicateFile, keeping keep: DuplicateFile, hash: String, root: URL, isAppContainer: Bool) throws {
        guard file.url.standardizedFileURL != keep.url.standardizedFileURL,
              Self.isAllowed(file.url, root: root, isAppContainer: isAppContainer),
              Self.isAllowed(keep.url, root: root, isAppContainer: isAppContainer) else { throw DeletionError.protectedLocation }
        var coordinationError: NSError?
        var failure: (any Error)?
        NSFileCoordinator().coordinate(readingItemAt: keep.url, options: [], writingItemAt: file.url, options: .forDeleting, error: &coordinationError) { keptURL, removedURL in
            do {
                guard Self.isAllowed(removedURL, root: root, isAppContainer: isAppContainer),
                      Self.isAllowed(keptURL, root: root, isAppContainer: isAppContainer) else { throw DeletionError.protectedLocation }
                let kept = DuplicateFile(url: keptURL, size: keep.size, modified: keep.modified, identity: keep.identity)
                let removed = DuplicateFile(url: removedURL, size: file.size, modified: file.modified, identity: file.identity)
                guard try DuplicateEngine.digest(kept) == hash, try DuplicateEngine.digest(removed) == hash else {
                    throw NSError(domain: "OrbitDisk", code: 2, userInfo: [NSLocalizedDescriptionKey: "Inhalte sind nicht mehr identisch. Bitte erneut vergleichen."])
                }
                try Task.checkCancellation()
                try FileManager.default.removeItem(at: removedURL)
            } catch { failure = error }
        }
        if let coordinationError { throw coordinationError }
        if let failure { throw failure }
    }
    func remove(_ url: URL, root: URL, isAppContainer: Bool) throws {
        guard Self.isAllowed(url, root: root, isAppContainer: isAppContainer) else { throw DeletionError.protectedLocation }
        let coordinator = NSFileCoordinator()
        var coordinationError: NSError?
        var removalError: (any Error)?
        coordinator.coordinate(writingItemAt: url, options: .forDeleting, error: &coordinationError) { coordinatedURL in
            do {
                guard Self.isAllowed(coordinatedURL, root: root, isAppContainer: isAppContainer) else { throw DeletionError.protectedLocation }
                try FileManager.default.removeItem(at: coordinatedURL)
            } catch { removalError = error }
        }
        if let coordinationError { throw coordinationError }
        if let removalError { throw removalError }
    }
}


enum FileLocations {
    static func browserDirectory(for node: FileNode, root: URL, isAppContainer: Bool) -> URL {
        let directory = node.isDirectory ? node.url : node.url.deletingLastPathComponent()
        guard isAppContainer else { return directory }
        let documents = root.appending(path: "Documents").standardizedFileURL
        let components = directory.standardizedFileURL.pathComponents
        let documentComponents = documents.pathComponents
        let inDocuments = components.count >= documentComponents.count && Array(components.prefix(documentComponents.count)) == documentComponents
        return inDocuments ? directory : documents
    }
}
