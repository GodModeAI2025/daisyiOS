import Foundation

enum DeletionSelection {
    nonisolated static func minimalRoots(_ nodes: [FileNode]) -> [FileNode] {
        let described: [(node: FileNode, depth: Int, path: String)] = nodes.map { node in
            let url = node.url.standardizedFileURL
            return (node, url.pathComponents.count, url.path)
        }
        let ordered = described.sorted { lhs, rhs in
            if lhs.depth != rhs.depth { return lhs.depth < rhs.depth }
            return lhs.path < rhs.path
        }
        var directories: Set<String> = []
        var seen: Set<String> = []
        var result: [FileNode] = []
        for entry in ordered {
            let node = entry.node
            let path = entry.path
            guard seen.insert(path).inserted else { continue }
            guard !covered(path, by: directories) else { continue }
            result.append(node)
            if node.isDirectory { directories.insert(path) }
        }
        return result
    }
    nonisolated static func covered(_ path: String, by roots: Set<String>) -> Bool {
        var current = URL(filePath: path).standardizedFileURL
        while true {
            if roots.contains(current.path) { return true }
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path { return false }
            current = parent
        }
    }
}
