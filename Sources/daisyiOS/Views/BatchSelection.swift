import SwiftUI
import Observation

@MainActor @Observable
final class BatchSelection {
    private(set) var nodes: [UUID: FileNode] = [:]
    private(set) var bytes: Int64 = 0
    var busy = false
    var message: String?
    var confirmation = false
    var task: Task<Void, Never>?
    var count: Int { nodes.count }
    func contains(_ node: FileNode) -> Bool { nodes[node.id] != nil }
    func toggle(_ node: FileNode) {
        if let removed = nodes.removeValue(forKey: node.id) { bytes -= removed.aggregateSize }
        else { nodes[node.id] = node; bytes += node.aggregateSize }
    }
    func select(_ entries: [FileNode]) {
        for node in entries where nodes[node.id] == nil { nodes[node.id] = node; bytes += node.aggregateSize }
    }
    func clear() { nodes = [:]; bytes = 0 }
    func delete(using result: ScanResult) {
        let targets = Array(nodes.values)
        busy = true
        message = nil
        task = Task {
            let outcome = await result.deleteNodes(targets)
            nodes = nodes.filter { !DeletionSelection.covered($0.value.url.path, by: outcome.removed) }
            bytes = nodes.values.reduce(0) { $0 + $1.aggregateSize }
            message = outcome.stopped ? "Gestoppt. Bereits entfernte Einträge: \(outcome.removed.count)." : outcome.failed > 0 ? "\(outcome.failed) Einträge nicht entfernt. Die übrige Auswahl bleibt erhalten." : "Ausgewählte Einträge entfernt."
            busy = false
        }
    }
}

struct SelectionCheckbox: View {
    let node: FileNode
    let selection: BatchSelection
    var body: some View {
        Button { selection.toggle(node) } label: {
            Image(systemName: selection.contains(node) ? "checkmark.circle.fill" : "circle")
                .font(.title2).frame(width: 44, height: 44).contentShape(Rectangle())
        }.buttonStyle(.plain).tint(.indigo)
            .accessibilityLabel(selection.contains(node) ? "\(node.name) abwählen" : "\(node.name) auswählen")
            .disabled(selection.busy)
    }
}

struct BatchSelectionBar: View {
    let selection: BatchSelection
    let result: ScanResult
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if selection.busy {
                BatchDeletionProgress(result: result)
                Button("Weitere Löschungen stoppen") { selection.task?.cancel() }
                    .buttonStyle(OrbitActionStyle())
            } else {
                if let message = selection.message { Text(message).font(.footnote).foregroundStyle(.secondary) }
                if selection.count > 0 {
                    Text("\(selection.count) ausgewählt · \(selection.bytes.formattedBytes)").font(.subheadline.weight(.semibold))
                    Button("Auswahl löschen …", role: .destructive) { selection.confirmation = true }
                        .buttonStyle(OrbitActionStyle()).disabled(result.isDeleting)
                }
            }
        }.padding(.horizontal, 20).padding(.vertical, 12)
            .background(.regularMaterial)
            .alert("Auswahl wirklich löschen?", isPresented: Bindable(selection).confirmation) {
                Button("Abbrechen", role: .cancel) {}
                Button("Auswahl endgültig löschen", role: .destructive) { selection.delete(using: result) }
            } message: {
                Text("\(selection.count) ausgewählte Einträge (\(selection.bytes.formattedBytes)) werden endgültig entfernt. Ausgewählte Ordner werden mit ihrem gesamten Inhalt gelöscht. Bei synchronisierten Dateien kann dies andere Geräte betreffen. Diese Aktion lässt sich hier nicht rückgängig machen.")
            }
    }
}
private struct BatchDeletionProgress: View {
    let result: ScanResult
    var body: some View { ProgressView("Einträge werden entfernt: \(result.deletionProgress)") }
}
