import SwiftUI
import QuickLook

struct FolderDetailView: View {
    let node: FileNode
    var title: String? = nil
    let result: ScanResult
    @State private var query = ""
    @State private var selected: FileNode?
    @State private var selectionRevision = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var selection: Binding<FileNode?> {
        Binding(get: { selected }, set: { value in
            selected = value
            if value != nil { selectionRevision += 1 }
        })
    }
    var body: some View {
        ScrollViewReader { scroll in
            ScrollView {
                if let current = result.find(node.url) {
                    VStack(spacing: 20) {
                        VStack(spacing: 12) {
                            Label("DEIN SPEICHER, NEU GESEHEN", systemImage: "sparkles")
                                .font(.caption.weight(.semibold)).foregroundStyle(.indigo)
                            SunburstChart(root: current, selected: selection).frame(height: 300)
                            Text("Tippe einen Bereich, um ihn zu entdecken.")
                                .font(.subheadline).foregroundStyle(.secondary)
                            Text("\(current.fileCount) Dateien · \(max(0, current.directoryCount - 1)) Ordner")
                                .font(.subheadline).monospacedDigit()
                        }.cosmicCard()
                        FileActionPanel(node: selected.flatMap { result.find($0.url) } ?? current, result: result, isSelection: selected != nil) {
                            withAnimation(reduceMotion ? nil : .spring(response: 0.4)) { selected = nil }
                        }
                        .id(selected?.id ?? current.id)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 12)))
                        .id("file-actions")
                        FolderContents(node: current, result: result, query: query, selected: selection)
                    }
                    .animation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.85), value: current.aggregateSize)
                    .padding(20)
                    .frame(maxWidth: 850)
                    .frame(maxWidth: .infinity)
                } else {
                    ContentUnavailableView("Ordner gelöscht", systemImage: "folder.badge.minus", description: Text("Kehre zum übergeordneten Ordner zurück."))
                }
            }
            .onChange(of: selectionRevision) { _, _ in
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) {
                    scroll.scrollTo("file-actions", anchor: .top)
                }
            }
            .cosmicScreen()
            .navigationTitle(title ?? node.name)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Dateien und Ordner suchen")
        }
    }
}

struct FolderContents: View {
    let node: FileNode
    let result: ScanResult
    let query: String
    @Binding var selected: FileNode?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Inhalt").font(.title3.bold())
            Text("Nach Speicherbedarf sortiert").font(.subheadline).foregroundStyle(.secondary)
            let children = node.children.sorted { $0.aggregateSize > $1.aggregateSize }.filter { query.isEmpty || $0.name.localizedStandardContains(query) }
            if children.isEmpty {
                ContentUnavailableView(query.isEmpty ? "Ordner ist leer" : "Keine Treffer", systemImage: query.isEmpty ? "folder" : "magnifyingglass")
            }
            ForEach(children) { child in
                VStack(spacing: 12) {
                    Button {
                        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.42, dampingFraction: 0.8)) { selected = child }
                    } label: { FileRow(node: child) }
                        .buttonStyle(.plain).frame(minHeight: 44)
                        .accessibilityHint("Zeigt Aktionen für diesen Eintrag")
                    if child.isDirectory {
                        NavigationLink { FolderDetailView(node: child, result: result) } label: {
                            Label("Ordner erkunden", systemImage: "arrow.down.right.and.arrow.up.left")
                        }.font(.subheadline)
                    }
                    Divider()
                }
            }
        }.cosmicCard()
    }
}

struct FileActionPanel: View {
    let node: FileNode
    let result: ScanResult
    var isSelection = false
    var onDelete: () -> Void = {}
    @State private var previewURL: URL?
    @State private var showBrowser = false
    @State private var pendingDeletion: FileNode?
    @State private var deletionError: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                Image(systemName: node.isDirectory ? "folder.fill" : "doc.fill").font(.title2).foregroundStyle(.indigo)
                VStack(alignment: .leading, spacing: 5) {
                    Text(isSelection ? "Ausgewählt" : "Dieser Ordner").font(.caption).foregroundStyle(.secondary)
                    Text(node.url == result.root.url && result.isAppContainer ? "App-Container" : node.name).font(.headline).textSelection(.enabled)
                    Text(node.aggregateSize.formattedBytes).font(.title2.bold()).fontDesign(.rounded)
                }
            }
            if node.isDirectory, isSelection {
                NavigationLink { FolderDetailView(node: node, result: result) } label: {
                    Label("Ordner erkunden", systemImage: "arrow.down.right.and.arrow.up.left")
                }.buttonStyle(.borderedProminent).controlSize(.large)
            }
            Button { showBrowser = true } label: {
                Label("In Dateien anzeigen", systemImage: "folder.badge.gearshape")
            }.buttonStyle(.bordered).controlSize(.large)
            if !node.isDirectory, QLPreviewController.canPreview(node.url as NSURL) {
                Button { previewURL = node.url } label: { Label("Quick Look", systemImage: "eye") }
                    .buttonStyle(.bordered).controlSize(.large)
            }
            Button(role: .destructive) { pendingDeletion = node } label: {
                Label(result.isDeleting ? "Wird gelöscht …" : "Löschen …", systemImage: "trash")
            }.buttonStyle(.bordered).controlSize(.large)
                .disabled(!result.canDelete(node) || result.isDeleting)
            if !result.canDelete(node) {
                Text("Der Analyseordner und interne App-Einstellungen sind vor dem Löschen geschützt.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            Text(result.isAppContainer && FileLocations.browserDirectory(for: node, root: result.root.url, isAppContainer: true) != (node.isDirectory ? node.url : node.url.deletingLastPathComponent()) ? "Interne App-Ordner sind in Dateien nicht sichtbar. Hier öffnet sich der Dokumente-Bereich." : "Öffnet die Dateien-Auswahl am gewünschten Speicherort, sofern verfügbar.")
                .font(.footnote).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).cosmicCard()
        .quickLookPreview($previewURL)
        .sheet(isPresented: $showBrowser) {
            LocationBrowser(startingDirectory: FileLocations.browserDirectory(for: node, root: result.root.url, isAppContainer: result.isAppContainer))
        }
        .alert("Wirklich löschen?", item: $pendingDeletion) { target in
            Button("Abbrechen", role: .cancel) {}
            Button("Endgültig löschen", role: .destructive) {
                Task {
                    if await result.delete(target) {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.4)) { onDelete() }
                    } else { deletionError = result.errorMessage }
                }
            }
        } message: { target in
            Text("„\(target.name)“: " + (target.isDirectory ? "Der Ordner und sein gesamter Inhalt (\(target.fileCount) Dateien) werden gelöscht. Bei synchronisierten Ordnern kann das auch andere Geräte betreffen. Diese Aktion kann hier nicht rückgängig gemacht werden." : "Die Datei wird gelöscht. Bei synchronisierten Dateien kann das auch andere Geräte betreffen. Diese Aktion kann hier nicht rückgängig gemacht werden."))
        }
        .alert("Löschen nicht möglich", item: $deletionError) { _ in
            Button("OK") {}
        } message: { error in Text(error) }
    }
}
