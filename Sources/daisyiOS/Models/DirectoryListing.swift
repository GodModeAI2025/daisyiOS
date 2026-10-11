import Foundation

enum EntryFilter: String, CaseIterable, Identifiable, Sendable {
    case all = "Alle Einträge"
    case folders = "Nur Ordner"
    case files = "Nur Dateien"
    var id: Self { self }
}

enum EntrySort: String, CaseIterable, Identifiable, Sendable {
    case largest = "Größte zuerst"
    case smallest = "Kleinste zuerst"
    case name = "Name A–Z"
    var id: Self { self }
}

enum DirectoryListing {
    nonisolated static func entries(_ entries: [FileNode], query: String, filter: EntryFilter, sort: EntrySort) -> [FileNode] {
        entries.filter { entry in
            (query.isEmpty || entry.name.localizedStandardContains(query)) &&
            (filter == .all || (filter == .folders ? entry.isDirectory : !entry.isDirectory))
        }.sorted { lhs, rhs in
            if lhs.isDirectory != rhs.isDirectory { return lhs.isDirectory }
            switch sort {
            case .largest:
                if lhs.aggregateSize != rhs.aggregateSize { return lhs.aggregateSize > rhs.aggregateSize }
            case .smallest:
                if lhs.aggregateSize != rhs.aggregateSize { return lhs.aggregateSize < rhs.aggregateSize }
            case .name: break
            }
            let comparison = lhs.name.localizedStandardCompare(rhs.name)
            return comparison == .orderedSame ? lhs.id.uuidString < rhs.id.uuidString : comparison == .orderedAscending
        }
    }
}
