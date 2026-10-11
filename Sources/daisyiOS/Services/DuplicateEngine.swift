import Foundation
import CryptoKit

struct DuplicateFile: Identifiable, Sendable {
    var id: String { url.path }
    let url: URL
    let size: Int64
    let modified: Date
    let identity: String?
}
struct DuplicateGroup: Identifiable, Sendable {
    var id: String { hash }
    let hash: String
    let files: [DuplicateFile]
    var extraBytes: Int64 { (files.first?.size ?? 0) * Int64(max(0, files.count - 1)) }
}
struct DuplicateProgress: Sendable {
    var phase: String
    var completed: Int
    var total: Int
}
enum DuplicateEvent: Sendable {
    case progress(DuplicateProgress)
    case finished([DuplicateGroup], unreadable: Int, excluded: Int)
    case failed(String)
}
enum DuplicateEngine {
    static func scan(_ root: FileNode, lease: FolderAccessLease?) -> AsyncStream<DuplicateEvent> {
        AsyncStream(bufferingPolicy: .bufferingNewest(2)) { continuation in
            let task = Task.detached(priority: .userInitiated) {
                defer { withExtendedLifetime(lease) {}; continuation.finish() }
                var unreadable = 0
                var excluded = 0
                var bySize: [Int64: [DuplicateFile]] = [:]
                var lastUpdate = Date.distantPast
                var visited = 0
                let base = root.url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
                func publish(_ phase: String, _ count: Int, _ total: Int, force: Bool = false) {
                    guard force || Date().timeIntervalSince(lastUpdate) > 0.15 else { return }
                    lastUpdate = Date()
                    continuation.yield(.progress(DuplicateProgress(phase: phase, completed: count, total: total)))
                }
                func gather(_ node: FileNode) throws {
                    try Task.checkCancellation()
                    let resolved = node.url.standardizedFileURL.resolvingSymlinksInPath().pathComponents
                    guard resolved.count >= base.count, Array(resolved.prefix(base.count)) == base else { excluded += max(1, node.fileCount); return }
                    if node.isDirectory {
                        do {
                            let values = try node.url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
                            guard values.isDirectory == true, values.isSymbolicLink != true else { excluded += max(1, node.fileCount); return }
                        } catch { unreadable += max(1, node.fileCount); return }
                        if [".git", ".hg", ".svn", "node_modules", ".build", ".swiftpm", "deriveddata", "caches", ".cache", "pods", "__pycache__", ".venv"].contains(node.name.lowercased()) {
                            excluded += node.fileCount; return
                        }
                        for child in node.children { try gather(child) }
                    } else {
                        visited += 1
                        do {
                            let attributes = try FileManager.default.attributesOfItem(atPath: node.url.path)
                            guard attributes[.type] as? FileAttributeType == .typeRegular,
                                  let size = (attributes[.size] as? NSNumber)?.int64Value, size > 0,
                                  ((attributes[.referenceCount] as? NSNumber)?.intValue ?? 1) <= 1 else { excluded += 1; return }
                            let inode = (attributes[.systemFileNumber] as? NSNumber)?.uint64Value ?? 0
                            let device = (attributes[.systemNumber] as? NSNumber)?.int64Value ?? 0
                            let file = DuplicateFile(url: node.url, size: size, modified: attributes[.modificationDate] as? Date ?? .distantPast, identity: inode > 0 ? "\(device):\(inode)" : nil)
                            bySize[size, default: []].append(file)
                        } catch { unreadable += 1 }
                        publish("Dateien werden erfasst …", visited, root.fileCount)
                    }
                }
                do {
                    publish("Dateien werden erfasst …", 0, root.fileCount, force: true)
                    try gather(root)
                    let candidates = bySize.values.filter { $0.count > 1 }.flatMap { $0 }
                    var matching: [String: [DuplicateFile]] = [:]
                    for (index, file) in candidates.enumerated() {
                        try Task.checkCancellation()
                        do {
                            let hash = try digest(file)
                            matching[hash, default: []].append(file)
                        } catch is CancellationError { throw CancellationError() }
                        catch { unreadable += 1 }
                        publish("Dateiinhalte werden verglichen …", index + 1, candidates.count)
                    }
                    let groups = matching.compactMap { hash, files -> DuplicateGroup? in
                        guard files.count > 1 else { return nil }
                        return DuplicateGroup(hash: hash, files: files.sorted { $0.url.path < $1.url.path })
                    }.sorted { $0.extraBytes == $1.extraBytes ? $0.hash < $1.hash : $0.extraBytes > $1.extraBytes }
                    try Task.checkCancellation()
                    continuation.yield(.finished(groups, unreadable: unreadable, excluded: excluded))
                } catch is CancellationError {} catch { continuation.yield(.failed(error.localizedDescription)) }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    static func digest(_ file: DuplicateFile) throws -> String {
        try validate(file)
        let handle = try FileHandle(forReadingFrom: file.url)
        defer { try? handle.close() }
        var hash = SHA256()
        var bytesRead: Int64 = 0
        while true {
            try Task.checkCancellation()
            guard let data = try handle.read(upToCount: 1_048_576), !data.isEmpty else { break }
            bytesRead += Int64(data.count)
            hash.update(data: data)
        }
        guard bytesRead == file.size else {
            throw NSError(domain: "OrbitDisk", code: 3, userInfo: [NSLocalizedDescriptionKey: "Datei konnte nicht vollständig gelesen werden. Bitte Dateianbieter prüfen und erneut vergleichen."])
        }
        try validate(file)
        return hash.finalize().map { String(format: "%02x", $0) }.joined()
    }
    static func validate(_ file: DuplicateFile) throws {
        let a = try FileManager.default.attributesOfItem(atPath: file.url.path)
        let inode = (a[.systemFileNumber] as? NSNumber)?.uint64Value ?? 0
        let device = (a[.systemNumber] as? NSNumber)?.int64Value ?? 0
        let identity = inode > 0 ? "\(device):\(inode)" : nil
        guard a[.type] as? FileAttributeType == .typeRegular,
              (a[.size] as? NSNumber)?.int64Value == file.size,
              a[.modificationDate] as? Date == file.modified,
              identity == file.identity,
              ((a[.referenceCount] as? NSNumber)?.intValue ?? 1) <= 1 else {
            throw NSError(domain: "OrbitDisk", code: 1, userInfo: [NSLocalizedDescriptionKey: "Datei wurde verändert oder ist nicht mehr als einzelne Kopie verfügbar. Bitte erneut suchen."])
        }
    }
}
