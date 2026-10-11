import Foundation

enum CleanupKind: String, Sendable {
    case temporary = "Temporäre Daten"
    case logs = "Protokolle und Diagnoseberichte"
    case caches = "Cache-Daten"
    case build = "Erzeugte Build-Daten"
    case downloads = "Unvollständige Downloads"
}
struct CleanupCandidate: Identifiable, Sendable {
    var id: UUID { node.id }
    let node: FileNode
    let kind: CleanupKind
    let reason: String
}
enum CleanupCandidates {
    nonisolated static func find(in root: FileNode) -> [CleanupCandidate] {
        func protected(_ node: FileNode) -> Bool {
            let name = node.name.lowercased()
            return [".git", ".hg", ".svn", "backup", "backups", "mobilesync"].contains(name) || name.hasPrefix("com.apple.") || ["cloudkit", "keychains", "preferences"].contains(name) || name.hasSuffix(".backupdb") || name.hasSuffix(".photoslibrary") || name.hasSuffix(".photolibrary")
        }
        func containsProtected(_ node: FileNode) -> Bool {
            if Task.isCancelled || protected(node) { return true }
            return node.children.contains { containsProtected($0) }
        }
        guard !protected(root) else { return [] }
        var found: [CleanupCandidate] = []
        func visit(_ node: FileNode, inherited: CleanupKind?) {
            guard !Task.isCancelled else { return }
            guard !protected(node) else { return }
            let kind = category(node) ?? inherited
            if let kind, !node.isDirectory || !containsProtected(node) {
                found.append(CleanupCandidate(node: node, kind: kind, reason: "Name oder Speicherort deutet auf \(kind.rawValue.lowercased()) hin. Inhalt vor dem Löschen prüfen; die Datei kann noch benötigt werden."))
            } else {
                for child in node.children { visit(child, inherited: kind) }
            }
        }
        for child in root.children { visit(child, inherited: category(root)) }
        return found.sorted { $0.node.aggregateSize > $1.node.aggregateSize }
    }
    nonisolated private static func category(_ node: FileNode) -> CleanupKind? {
        let name = node.name.lowercased()
        if node.isDirectory {
            if ["tmp", "temp", "temporary", ".tmp"].contains(name) { return .temporary }
            if ["cache", "caches", ".cache"].contains(name) { return .caches }
            if ["logs", "diagnosticreports"].contains(name) { return .logs }
            if ["deriveddata", ".build", "__pycache__"].contains(name) { return .build }
        } else {
            if ["tmp", "temp"].contains(node.url.pathExtension.lowercased()) { return .temporary }
            if name.range(of: #"\.log(?:\.\d+)?$"#, options: .regularExpression) != nil || ["ips", "crash"].contains(node.url.pathExtension.lowercased()) { return .logs }
            if ["part", "download", "crdownload"].contains(node.url.pathExtension.lowercased()) { return .downloads }
        }
        return nil
    }
}
