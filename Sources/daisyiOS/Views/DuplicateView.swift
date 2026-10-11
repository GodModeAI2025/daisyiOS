import SwiftUI

struct DuplicateView: View {
    let root: FileNode
    let result: ScanResult
    @State private var groups: [DuplicateGroup] = []
    @State private var progress = DuplicateProgress(phase: "Suche wird vorbereitet …", completed: 0, total: 0)
    @State private var scanning = true
    @State private var stopped = false
    @State private var failureMessage: String?
    @State private var failures = 0
    @State private var excluded = 0
    @State private var revision = 0
    @State private var scanTask: Task<Void, Never>?
    var body: some View {
        List {
            Section {
                Text("Gleicher Inhalt, mehrere Kopien").font(.title2.bold())
                Text("Vergleicht Dateien in diesem Ordner und allen Unterordnern zunächst nach Größe, dann mit vollständigem SHA-256. Dateinamen müssen nicht übereinstimmen. Cloud-Dateien können dafür geladen werden.")
                Text("Basis ist die letzte Speicheranalyse; neue Dateien werden erst nach erneuter Analyse erfasst. Leere Dateien, Links, Versionsverwaltung, Paket- und Build-Caches werden ausgelassen. Nichts wird automatisch gelöscht.").foregroundStyle(.secondary)
            }
            if scanning {
                Section {
                    ProgressView(progress.phase)
                    if progress.total > 0 { Text("\(progress.completed) von \(progress.total)").monospacedDigit() }
                    Button("Suche abbrechen", role: .cancel) {
                        stopped = true; scanning = false; scanTask?.cancel()
                    }
                }
            } else if stopped {
                Text("Duplikatsuche abgebrochen")
            } else {
                if let failureMessage { Text(failureMessage).foregroundStyle(.secondary) }
                if failures > 0 { Text("Unvollständiger Vergleich: \(failures) Einträge waren nicht lesbar oder wurden während der Suche verändert.").foregroundStyle(.secondary) }
                if excluded > 0 { Text("\(excluded) Dateien aufgrund von Schutzregeln ausgelassen.").font(.caption).foregroundStyle(.secondary) }
                Section("\(groups.count) Gruppen mit identischem Inhalt") {
                    if groups.isEmpty { Text("Keine identischen Kopien unter den geprüften Dateien gefunden.") }
                    ForEach(groups) { group in
                        NavigationLink {
                            DuplicateGroupView(group: group, root: root.url, result: result)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(group.files.first?.url.lastPathComponent ?? "Duplikate").font(.headline)
                                Text("\(group.files.count) Kopien · \(group.extraBytes.formattedBytes) in zusätzlichen Kopien").font(.subheadline).foregroundStyle(.secondary)
                                Text("Kopie zum Behalten auswählen").font(.caption)
                            }
                        }
                    }
                }
                Button("Erneut vergleichen") { revision += 1 }
            }
        }.cosmicScreen().navigationTitle("Duplikate finden")
        .task(id: revision) {
            scanTask?.cancel()
            scanning = true; stopped = false; groups = []; failures = 0; failureMessage = nil; excluded = 0
            let snapshot = result.find(root.url) ?? root
            let lease = result.accessLease
            scanTask = Task {
                for await event in DuplicateEngine.scan(snapshot, lease: lease) {
                    guard !Task.isCancelled else { return }
                    switch event {
                    case .progress(let value): progress = value
                    case .finished(let found, let unreadable, let skipped):
                        groups = found; failures = unreadable; excluded = skipped
                    case .failed(let error): failures += 1; failureMessage = error
                    }
                }
                guard !Task.isCancelled else { return }
                scanning = false
            }
        }
        .onDisappear { scanTask?.cancel() }
    }
}

struct DuplicateGroupView: View {
    let group: DuplicateGroup
    let root: URL
    let result: ScanResult
    @State private var keepPath = ""
    @State private var confirm = false
    @State private var busy = false
    @State private var deletionTask: Task<Void, Never>?
    @State private var message: String?
    @State private var removed: Set<String> = []
    var remaining: [DuplicateFile] { group.files.filter { !removed.contains($0.id) } }
    var body: some View {
        List {
            Section {
                Text("Mindestens eine Kopie behalten").font(.title2.bold())
                Text("Wähle die Datei, die bleiben soll. Die übrigen Kopien werden erst nach Bestätigung entfernt und unmittelbar vorher erneut auf identischen Inhalt geprüft.")
                Text("Behalten: \(keepPath.isEmpty ? "Bitte Kopie auswählen" : relative(URL(filePath: keepPath)))").font(.headline)
            }
            Section("Kopien prüfen") {
                ForEach(remaining) { file in
                    VStack(alignment: .leading, spacing: 8) {
                        Button { keepPath = file.id } label: {
                            Label(relative(file.url), systemImage: keepPath == file.id ? "checkmark.circle.fill" : "circle")
                        }.buttonStyle(.plain).frame(minHeight: 44).disabled(busy || result.isDeleting)
                        Text(keepPath == file.id ? "Diese Kopie bleibt erhalten" : "Diese Kopie würde entfernt").font(.caption).foregroundStyle(.secondary)
                        NavigationLink {
                            ScrollView {
                                FileActionPanel(node: FileNode(name: file.url.lastPathComponent, url: file.url, isDirectory: false, size: file.size, aggregateSize: file.size, fileCount: 1, directoryCount: 0), result: result, allowsDeletion: false).padding(20)
                            }.cosmicScreen().navigationTitle(file.url.lastPathComponent)
                        } label: { Label("Vorschau und Speicherort", systemImage: "eye") }
                            .font(.subheadline)
                    }
                }
            }
            if busy {
                DuplicateDeletionStatus(result: result)
                Button("Weitere Löschungen stoppen", role: .cancel) { deletionTask?.cancel() }
            }
            if let message { Text(message).foregroundStyle(.secondary) }
            Button(remaining.count == 2 ? "Andere Kopie entfernen …" : "Übrige \(max(0, remaining.count - 1)) Kopien entfernen …", role: .destructive) { confirm = true }
                .disabled(busy || result.isDeleting || remaining.count < 2 || !remaining.contains { $0.id == keepPath })
        }.cosmicScreen().navigationTitle("Duplikate prüfen")
        .onAppear { if keepPath.isEmpty { keepPath = remaining.first?.id ?? "" } }
        .alert("Übrige Kopien wirklich löschen?", isPresented: $confirm) {
            Button("Abbrechen", role: .cancel) {}
            Button("Kopien endgültig löschen", role: .destructive) {
                guard let keep = remaining.first(where: { $0.id == keepPath }) else { return }
                let targets = remaining.filter { $0.id != keepPath }
                busy = true
                deletionTask = Task {
                    let outcome = await result.deleteDuplicateGroup(targets, keeping: keep, hash: group.hash)
                    removed.formUnion(outcome.removed)
                    if outcome.stopped { message = "Gestoppt. Bereits entfernte Kopien: \(outcome.removed.count). Die gewählte Kopie bleibt erhalten." }
                    else if outcome.failed > 0 { message = "\(outcome.failed) Kopien wurden nicht gelöscht: verändert, nicht erreichbar oder geschützt. Bitte erneut vergleichen." }
                    else { message = "Ausgewählte Kopie behalten; übrige Kopien entfernt." }
                    busy = false
                }
            }
        } message: {
            Text("Die Kopie „\(keepPath.replacingOccurrences(of: root.path + "/", with: ""))“ bleibt erhalten. \(remaining.count == 2 ? "Eine andere Kopie wird" : "\(max(0, remaining.count - 1)) andere Kopien werden") endgültig gelöscht. Bei synchronisierten Dateien betrifft das möglicherweise andere Geräte.")
        }
    }
    private func relative(_ url: URL) -> String { url.path.replacingOccurrences(of: root.path + "/", with: "") }
}

private struct DuplicateDeletionStatus: View {
    let result: ScanResult
    var body: some View { ProgressView("Kopien werden erneut geprüft und entfernt: \(result.deletionProgress)") }
}
