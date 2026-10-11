import Foundation

enum ScanEvent: Sendable {
    case progress(ScanProgress)
    case finished(FileNode)
    case failed(any Error)
}

actor ScanEngine {
    func scan(_ rootURL: URL, accessLease: FolderAccessLease? = nil) -> AsyncStream<ScanEvent> {
        // File-provider calls can block. Keep all traversal off the main actor,
        // with one worker rather than recursively spawning tasks per directory.
        AsyncStream(bufferingPolicy: .bufferingNewest(2)) { continuation in
            let task = Task.detached(priority: .userInitiated) {
                defer { withExtendedLifetime(accessLease) {} }
                var worker = ScanWorker(continuation: continuation)
                do {
                    let root = try worker.traverse(rootURL, isRoot: true)
                    try Task.checkCancellation()
                    worker.publish(force: true)
                    continuation.yield(.finished(root))
                } catch is CancellationError {
                } catch {
                    continuation.yield(.failed(error))
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}

private struct ScanWorker {
    let continuation: AsyncStream<ScanEvent>.Continuation
    private var progress = ScanProgress()
    private let start = Date()
    private var lastPublished = Date.distantPast
    private let keys: Set<URLResourceKey> = [.isDirectoryKey, .isSymbolicLinkKey, .fileSizeKey, .totalFileAllocatedSizeKey]

    init(continuation: AsyncStream<ScanEvent>.Continuation) {
        self.continuation = continuation
    }

    mutating func traverse(_ directory: URL, isRoot: Bool = false) throws -> FileNode {
        try Task.checkCancellation()
        progress.currentPath = directory.lastPathComponent
        publish()
        let entries: [URL]
        do {
            entries = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: Array(keys), options: [])
        } catch {
            if isRoot { throw error }
            progress.unreadableEntries += 1
            publish()
            return FileNode(name: directory.lastPathComponent, url: directory, isDirectory: true, size: 0, aggregateSize: 0, fileCount: 0, directoryCount: 1)
        }
        progress.directoriesScanned += 1
        let ownSize = Int64((try? directory.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0)
        progress.bytesScanned += ownSize
        var children: [FileNode] = []
        children.reserveCapacity(entries.count)
        var bytes = ownSize
        var files = 0
        var directories = 1
        for entry in entries {
            try Task.checkCancellation()
            progress.currentPath = entry.lastPathComponent
            do {
                let values = try entry.resourceValues(forKeys: keys)
                if values.isDirectory == true, values.isSymbolicLink != true {
                    let child = try traverse(entry)
                    children.append(child)
                    bytes += child.aggregateSize
                    files += child.fileCount
                    directories += child.directoryCount
                } else {
                    // A cloud placeholder can have zero allocated bytes but a
                    // meaningful logical size. Do not make it disappear.
                    let allocated = values.totalFileAllocatedSize ?? 0
                    let size = Int64(allocated > 0 ? allocated : values.fileSize ?? 0)
                    children.append(FileNode(name: entry.lastPathComponent, url: entry, isDirectory: false, size: size, aggregateSize: size, fileCount: 1, directoryCount: 0))
                    bytes += size
                    files += 1
                    progress.filesScanned += 1
                    progress.bytesScanned += size
                }
            } catch is CancellationError { throw CancellationError() }
            catch { progress.unreadableEntries += 1 }
            publish()
        }
        // Sort once on the worker, rather than on every UI update.
        children.sort { $0.aggregateSize > $1.aggregateSize }
        return FileNode(name: directory.lastPathComponent.isEmpty ? "/" : directory.lastPathComponent, url: directory, isDirectory: true, size: ownSize, aggregateSize: bytes, fileCount: files, directoryCount: directories, children: children)
    }

    mutating func publish(force: Bool = false) {
        let now = Date()
        guard force || now.timeIntervalSince(lastPublished) >= 0.15 else { return }
        lastPublished = now
        progress.elapsed = now.timeIntervalSince(start)
        continuation.yield(.progress(progress))
    }
}
