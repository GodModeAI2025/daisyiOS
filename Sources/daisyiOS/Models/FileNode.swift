import Foundation

struct FileNode: Identifiable, Sendable, Equatable {
    let id: UUID
    let name: String
    let url: URL
    let isDirectory: Bool
    var size: Int64
    var aggregateSize: Int64
    var fileCount: Int
    var directoryCount: Int
    var children: [FileNode]

    init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        isDirectory: Bool,
        size: Int64,
        aggregateSize: Int64,
        fileCount: Int,
        directoryCount: Int,
        children: [FileNode] = []
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.isDirectory = isDirectory
        self.size = size
        self.aggregateSize = aggregateSize
        self.fileCount = fileCount
        self.directoryCount = directoryCount
        self.children = children
    }
}
