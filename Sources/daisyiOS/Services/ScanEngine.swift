import Foundation

enum ScanEvent: Sendable {
    case progress(ScanProgress)
    case finished(FileNode)
    case failed(any Error)
}

actor ScanEngine {
    var maxParallelDirectories = 4

    func scan(_ rootURL: URL) -> AsyncStream<ScanEvent> {
        AsyncStream { continuation in
            let task = Task {
                let start = Date()
                do {
                    let counter = ScanCounter(start: start, continuation: continuation)
                    let root = try await self.traverse(rootURL, counter: counter)
                    try Task.checkCancellation()
                    await counter.publish()
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

    private func traverse(
        _ directoryURL: URL,
        counter: ScanCounter
    ) async throws -> FileNode {
        if Task.isCancelled { throw CancellationError() }

        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .totalFileAllocatedSizeKey
        ]
        let entries = try FileManager.default.contentsOfDirectory(
            at: directoryURL,
            includingPropertiesForKeys: Array(keys),
            options: []
        )

        let ownSizeValues = try? directoryURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
        let ownSize = Int64(ownSizeValues?.totalFileAllocatedSize ?? 0)

        var fileChildren: [FileNode] = []
        var subdirectories: [URL] = []
        var bytes = ownSize
        var fileCount = 0

        for entry in entries {
            try Task.checkCancellation()
            guard let values = try? entry.resourceValues(forKeys: keys) else { continue }
            if values.isDirectory == true, values.isSymbolicLink != true {
                subdirectories.append(entry)
            } else {
                let size = Int64(values.totalFileAllocatedSize ?? values.fileSize ?? 0)
                bytes += size
                fileCount += 1
                fileChildren.append(FileNode(
                    name: entry.lastPathComponent,
                    url: entry,
                    isDirectory: false,
                    size: size,
                    aggregateSize: size,
                    fileCount: 1,
                    directoryCount: 0,
                    children: []
                ))
            }
        }

        await counter.add(files: fileCount, bytes: bytes)
        var children = fileChildren
        var aggregateBytes = bytes
        var aggregateFiles = fileCount
        var aggregateDirectories = 1

        for batch in batches(subdirectories, size: maxParallelDirectories) {
            if Task.isCancelled { throw CancellationError() }
            let results = try await withThrowingTaskGroup(of: FileNode.self) { group in
                for subdirectory in batch {
                    group.addTask {
                        try await self.traverse(subdirectory, counter: counter)
                    }
                }
                var collected: [FileNode] = []
                for try await node in group {
                    collected.append(node)
                }
                return collected
            }
            for node in results {
                children.append(node)
                aggregateBytes += node.aggregateSize
                aggregateFiles += node.fileCount
                aggregateDirectories += node.directoryCount
            }

        }

        let name = directoryURL.lastPathComponent.isEmpty ? "/" : directoryURL.lastPathComponent
        return FileNode(
            name: name,
            url: directoryURL,
            isDirectory: true,
            size: ownSize,
            aggregateSize: aggregateBytes,
            fileCount: aggregateFiles,
            directoryCount: aggregateDirectories,
            children: children
        )
    }
}

func batches<T>(_ array: [T], size: Int) -> [[T]] {
    guard size > 0 else { return array.isEmpty ? [] : [array] }
    var result: [[T]] = []
    var index = 0
    while index < array.count {
        let end = min(index + size, array.count)
        result.append(Array(array[index..<end]))
        index = end
    }
    return result
}


private actor ScanCounter {
    private var progress = ScanProgress()
    private let start: Date
    private let continuation: AsyncStream<ScanEvent>.Continuation
    private var lastPublished = Date.distantPast

    init(start: Date, continuation: AsyncStream<ScanEvent>.Continuation) {
        self.start = start
        self.continuation = continuation
    }
    func add(files: Int, bytes: Int64) {
        progress.filesScanned += files
        progress.directoriesScanned += 1
        progress.bytesScanned += bytes
        if Date().timeIntervalSince(lastPublished) >= 0.1 { publish() }
    }
    func publish() {
        lastPublished = Date()
        progress.elapsed = lastPublished.timeIntervalSince(start)
        continuation.yield(.progress(progress))
    }
}
