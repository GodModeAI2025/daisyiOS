import SwiftUI
import QuickLook

struct FolderDetailView: View {
    let node: FileNode
    var title: String? = nil
    let result: ScanResult
    @Environment(\.dismiss) private var dismiss
    @State private var orbFolder: FileNode?
    @State private var showOrbFolder = false
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
                        if result.unreadableEntries > 0 {
                            Label("Unvollständig: \(result.unreadableEntries) Einträge nicht lesbar", systemImage: "exclamationmark.triangle")
                                .font(.subheadline).cosmicCard()
                        }
                        VStack(spacing: 12) {
                            Label("DEIN SPEICHER, NEU GESEHEN", systemImage: "sparkles")
                                .font(.caption.weight(.semibold)).foregroundStyle(.indigo)
                            SunburstChart(root: current, selected: selection, onOpenFolder: { folder in
                                orbFolder = folder
                                showOrbFolder = true
                            }, onGoBack: current.url == result.root.url ? nil : { dismiss() })
                                .frame(height: 300)
                            Label("Grau: sehr kleine Einträge und Ordnerbelegung", systemImage: "circle.fill")
                                .font(.caption).foregroundStyle(.secondary)
                            Text("Ordner im Orb antippen: Unterordner öffnen. Datei antippen: Aktionen anzeigen. In Unterordnern führt die Mitte zurück. Kleine Einträge findest du in der Liste.")
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
            .navigationDestination(isPresented: $showOrbFolder) {
                if let folder = orbFolder { FolderDetailView(node: folder, result: result) }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        NavigationLink { CleanupView(root: result.find(node.url) ?? node, result: result) } label: {
                            Label("Aufräumkandidaten finden", systemImage: "sparkles")
                        }
                        NavigationLink { DuplicateView(root: result.find(node.url) ?? node, result: result) } label: {
                            Label("Duplikate finden", systemImage: "document.on.document")
                        }
                    } label: { Label("Ordner prüfen", systemImage: "ellipsis.circle").labelStyle(.titleAndIcon) }
                }
            }
            .searchable(text: $query, prompt: "Dateien und Ordner suchen")
        }
    }
}

struct FolderContents: View {
    let node: FileNode
    let result: ScanResult
    let query: String
    @Binding var selected: FileNode?
    @State private var visibleChildren: [FileNode] = []
    @State private var preparing = true
    @State private var filter: EntryFilter = .all
    @State private var sort: EntrySort = .largest
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 16) {
            Text("Inhalt").font(.title3.bold())
            Text("Ordner stehen immer vor Dateien. Tippe einen Ordner, um seinen Inhalt zu sehen.")
                .font(.subheadline).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 10) {
                Menu {
                    Picker("Einträge anzeigen", selection: $filter) {
                        ForEach(EntryFilter.allCases) { value in Text(value.rawValue).tag(value) }
                    }
                } label: { Label(filter.rawValue, systemImage: "line.3.horizontal.decrease") }
                Menu {
                    Picker("Sortierung", selection: $sort) {
                        ForEach(EntrySort.allCases) { value in Text(value.rawValue).tag(value) }
                    }
                } label: { Label(sort.rawValue, systemImage: "arrow.up.arrow.down") }
            }.buttonStyle(.bordered).controlSize(.large)
            Text("\(visibleChildren.count) Einträge angezeigt").font(.caption).foregroundStyle(.secondary)
            if preparing { ProgressView("Dateiliste wird vorbereitet …") }
            if !preparing, visibleChildren.isEmpty {
                ContentUnavailableView(query.isEmpty && filter == .all ? "Ordner ist leer" : "Keine passenden Einträge", systemImage: "magnifyingglass", description: Text("Passe Filter oder Suche an."))
            }
            ForEach(visibleChildren) { child in
                VStack(spacing: 12) {
                    if child.isDirectory {
                        NavigationLink { FolderDetailView(node: child, result: result) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    FileRow(node: child)
                                    Label("Unterordner öffnen", systemImage: "chevron.right").font(.caption)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.right")
                            }.frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle())
                        }.buttonStyle(.plain).frame(minHeight: 44)
                            .accessibilityHint("Öffnet den Ordner in OrbitDisk")
                    } else {
                        Button { select(child) } label: { FileRow(node: child).frame(maxWidth: .infinity, alignment: .leading).contentShape(Rectangle()) }
                            .buttonStyle(.plain).frame(minHeight: 44)
                            .accessibilityHint("Zeigt Vorschau und Dateiaktionen")
                    }
                    Button { select(child) } label: {
                        Label(child.isDirectory ? "Ordneraktionen anzeigen" : "Dateiaktionen anzeigen", systemImage: "ellipsis.circle")
                    }.font(.subheadline).buttonStyle(.bordered)
                    Divider()
                }
            }
        }.cosmicCard()
        .task(id: "\(node.id)-\(node.aggregateSize)-\(node.fileCount)-\(node.directoryCount)-\(node.children.count)-\(query)-\(filter.rawValue)-\(sort.rawValue)") {
            preparing = true
            let snapshot = node.children
            let search = query
            let chosenFilter = filter
            let chosenSort = sort
            let worker = Task.detached(priority: .userInitiated) {
                DirectoryListing.entries(snapshot, query: search, filter: chosenFilter, sort: chosenSort)
            }
            let children = await worker.value
            guard !Task.isCancelled else { return }
            visibleChildren = children
            preparing = false
        }
    }
    private func select(_ child: FileNode) {
        withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.42, dampingFraction: 0.8)) { selected = child }
    }

}

struct FileActionPanel: View {
    let node: FileNode
    let result: ScanResult
    var isSelection = false
    var allowsDeletion = true
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
                    Text(isSelection ? "Ausgewählt" : node.isDirectory ? "Dieser Ordner" : "Diese Datei").font(.caption).foregroundStyle(.secondary)
                    Text(node.url == result.root.url && result.isAppContainer ? "App-Container" : node.name).font(.headline).textSelection(.enabled)
                    Text(node.aggregateSize.formattedBytes).font(.title2.bold()).fontDesign(.rounded)
                }
            }
            if node.isDirectory, isSelection {
                NavigationLink { FolderDetailView(node: node, result: result) } label: {
                    Label("Unterordner in OrbitDisk öffnen", systemImage: "folder.badge.plus")
                }.buttonStyle(.borderedProminent).controlSize(.large)
            }
            Button { showBrowser = true } label: {
                Label("Speicherort in Dateien anzeigen", systemImage: "folder")
            }.buttonStyle(.bordered).controlSize(.large)
            if !node.isDirectory, QLPreviewController.canPreview(node.url as NSURL) {
                Button { previewURL = node.url } label: { Label("Dateivorschau (Quick Look)", systemImage: "eye") }
                    .buttonStyle(.bordered).controlSize(.large)
            }
            if allowsDeletion {
            Button(role: .destructive) { pendingDeletion = node } label: {
                Label(result.isDeleting ? "Wird gelöscht …" : "Löschen …", systemImage: "trash")
            }.buttonStyle(.bordered).controlSize(.large)
                .disabled(!result.canDelete(node) || result.isDeleting)
            if !result.canDelete(node) {
                Text("Der Analyseordner und interne App-Einstellungen sind vor dem Löschen geschützt.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
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
