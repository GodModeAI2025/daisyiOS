import SwiftUI

struct CleanupView: View {
    let root: FileNode
    let result: ScanResult
    @State private var candidates: [CleanupCandidate] = []
    @State private var loading = true
    var body: some View {
        List {
            Section {
                Text("Was könnte hier gelöscht werden?").font(.title2.bold())
                Text("Durchsucht diesen Ordner und alle Unterordner nach temporären Daten, Logs, Caches, Build-Resten und unvollständigen Downloads. Das sind Vorschläge anhand von Namen und Speicherorten, keine Garantie für gefahrloses Löschen.")
                Text("Basis ist die letzte Speicheranalyse; neue Dateien: Ordner erneut analysieren. Nichts wird automatisch ausgewählt oder gelöscht. Backups, Fotomediatheken und Versionsverwaltung werden ausgelassen.").foregroundStyle(.secondary)
            }
            if loading { ProgressView("Aufräumkandidaten werden ermittelt …") }
            else {
                Section("\(candidates.count) Kandidaten · \(candidates.reduce(Int64(0)) { $0 + $1.node.aggregateSize }.formattedBytes)") {
                    if candidates.isEmpty { Text("Keine passenden temporären Daten oder Protokolle gefunden.") }
                    ForEach(candidates) { candidate in
                        NavigationLink {
                            CleanupCandidateDetail(candidate: candidate, root: root.url, result: result)
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                FileRow(node: candidate.node)
                                Text(candidate.kind.rawValue).font(.caption).foregroundStyle(.secondary)
                                Text(candidate.node.url.path.replacingOccurrences(of: root.url.path + "/", with: "")).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                        }
                    }
                }
            }
        }.cosmicScreen().navigationTitle("Aufräumkandidaten")
        .task(id: "\(result.root.aggregateSize)-\(result.root.fileCount)-\(result.root.directoryCount)") {
            loading = true
            let snapshot = result.find(root.url) ?? root
            let work = Task.detached(priority: .userInitiated) { CleanupCandidates.find(in: snapshot) }
            let items = await work.value
            guard !Task.isCancelled else { return }
            candidates = items
            loading = false
        }
    }
}

private struct CleanupCandidateDetail: View {
    let candidate: CleanupCandidate
    let root: URL
    let result: ScanResult
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            if let node = result.find(candidate.node.url) {
                VStack(alignment: .leading, spacing: 20) {
                    Text(candidate.kind.rawValue).font(.title2.bold())
                    Text(candidate.reason)
                    Text(node.url.path.replacingOccurrences(of: root.path + "/", with: "")).font(.caption).foregroundStyle(.secondary)
                    FileActionPanel(node: node, result: result, isSelection: true, onDelete: { dismiss() })
                }.padding(20)
            } else { ContentUnavailableView("Eintrag entfernt", systemImage: "checkmark.circle") }
        }.cosmicScreen().navigationTitle("Kandidat prüfen")
    }
}
