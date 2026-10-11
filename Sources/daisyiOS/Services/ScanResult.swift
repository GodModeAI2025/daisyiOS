import Foundation
import Observation

@MainActor @Observable
final class ScanResult {
    private(set) var root: FileNode
    let isAppContainer: Bool
    let unreadableEntries: Int
    private let accessLease: FolderAccessLease?
    var isDeleting = false
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
        if url.standardizedFileURL == target.standardizedFileURL { return self }
        for child in children { if let found = child.find(target) { return found } }
        return nil
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
