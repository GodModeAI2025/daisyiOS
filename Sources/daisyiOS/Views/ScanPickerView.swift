import SwiftUI
import UniformTypeIdentifiers
import Observation

@MainActor
@Observable
final class ScanModel {
    var progress: ScanProgress?
    var result: ScanResult?
    var root: FileNode? { result?.root }
    var errorMessage: String?
    var isScanning = false
    var scannedFolderName: String?
    var savedFolders: [AccessStore.Folder] = []
    var cancelled = false
    var startedAt = Date()
    var lastUpdate = Date()
    private var scanID = UUID()

    func loadFolders() async { savedFolders = await AccessStore.shared.folders }

    func reopen(_ folder: AccessStore.Folder) async {
        do { scanFolder(try await AccessStore.shared.url(for: folder)) }
        catch { errorMessage = "Ordner nicht mehr verfügbar. Bitte erneut auswählen. " + error.localizedDescription }
    }

    private var scanTask: Task<Void, Never>?
    private var accessURL: URL?
    private var accessLease: FolderAccessLease?

    func scanFolder(_ url: URL) {
        guard !isScanning else { return }
        accessLease = FolderAccessLease(url: url)
        accessURL = url
        startScan(of: url, folderName: url.lastPathComponent)
    }

    func cancel() {
        scanID = UUID()
        cancelled = true
        scanTask?.cancel()
        scanTask = nil
        isScanning = false
        accessLease = nil
    }

    private func startScan(of url: URL, folderName: String) {
        scanID = UUID()
        let currentID = scanID
        let lease = accessLease
        startedAt = Date()
        lastUpdate = startedAt
        cancelled = false
        isScanning = true
        progress = ScanProgress()
        result = nil
        errorMessage = nil
        scannedFolderName = folderName

        scanTask = Task { [weak self] in
            defer { withExtendedLifetime(lease) {} }
            let engine = ScanEngine()
            for await event in await engine.scan(url, accessLease: lease) {
                guard let self, self.scanID == currentID, !Task.isCancelled else { return }
                switch event {
                case .progress(let progress):
                    self.progress = progress
                    self.lastUpdate = Date()
                case .finished(let node):
                    self.result = ScanResult(root: node, isAppContainer: url.standardizedFileURL == URL(fileURLWithPath: NSHomeDirectory()).standardizedFileURL, accessLease: lease, unreadableEntries: self.progress?.unreadableEntries ?? 0)
                    if let accessURL = self.accessURL {
                        do {
                            try await AccessStore.shared.add(name: folderName, url: accessURL)
                            await self.loadFolders()
                        } catch { self.errorMessage = "Der Ordnerzugriff konnte nicht gespeichert werden: " + error.localizedDescription }
                    }
                case .failed(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
            if self?.scanID == currentID { self?.finishScan() }
        }
    }

    private func finishScan() {
        scanTask = nil
        isScanning = false
    }
}

struct ScanPickerView: View {
    @State private var model = ScanModel()
    @State private var showFolderPicker = false
    @State private var showResult = false

    var body: some View {
        NavigationStack {
            List {
                if !model.isScanning {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("DEIN DIGITALER KOSMOS", systemImage: "sparkles").font(.caption.weight(.semibold)).foregroundStyle(.indigo)
                            Text("Was möchtest du analysieren?").font(.title.bold()).fontDesign(.rounded)
                            Text("Ein Ordner. Ein Laufwerk. Eine neue Perspektive auf deine Daten.").foregroundStyle(.secondary)
                        }.padding(.vertical, 12).listRowBackground(Color.clear)
                    }
                    Section("Analyse starten") {
                        Button {
                            showFolderPicker = true
                        } label: {
                            Label("Ordner oder Datenträger wählen", systemImage: "externaldrive.badge.plus")
                        }
                        .disabled(model.isScanning)
                    }

                }
                if model.isScanning {
                    Section {
                        ScanActivityView(model: model)
                    }
                }

                if let error = model.errorMessage {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                    }
                }

                if model.cancelled, !model.isScanning {
                    Section { Label("Scan abgebrochen", systemImage: "stop.circle") }
                }
                if let progress = model.progress, !model.isScanning, progress.unreadableEntries > 0 {
                    Section {
                        Label("Analyse unvollständig", systemImage: "exclamationmark.triangle")
                        Text("\(progress.unreadableEntries) Einträge konnten vom Dateianbieter nicht gelesen werden. Die angezeigte Größe enthält nur erreichbare Dateien.")
                    }
                }
                if let result = model.result {
                    let root = result.root
                    Section("Ergebnis") {
                        NavigationLink {
                            FolderDetailView(node: root, title: model.scannedFolderName, result: result)
                        } label: {
                            Label {
                                VStack(alignment: .leading) {
                                    Text(model.scannedFolderName ?? root.name).font(.headline)
                                    Text("\(root.aggregateSize.formattedBytes) · \(root.fileCount) Dateien").foregroundStyle(.secondary)
                                }
                            } icon: { Image(systemName: "chart.pie.fill").foregroundStyle(.indigo) }
                        }
                    }
                }
                if !model.savedFolders.isEmpty {
                    Section("Zuletzt analysiert") {
                        ForEach(model.savedFolders) { folder in
                            Button { Task { await model.reopen(folder) } } label: {
                                Label(folder.name, systemImage: "folder")
                            }.disabled(model.isScanning)
                        }
                    }
                }
                Section {
                    Link("Datenschutzerklärung", destination: URL(string: "https://www.mobilebox-consulting.de/datenschutzerkl%C3%A4rung-privacy-policy/")!)
                    Link("Support kontaktieren", destination: URL(string: "mailto:info@mobilebox-consulting.de")!)
                }
                Section {
                    Label("Lokal und privat", systemImage: "lock.shield")
                    Text("Wähle einen Ordner auf deinem Gerät, in iCloud Drive oder auf einem verbundenen Laufwerk. Bei Cloud-Dateien kann das Laden Zeit benötigen.")
                        .foregroundStyle(.secondary)
                }

            }
            .cosmicScreen()
            .navigationTitle("OrbitDisk")
            .navigationDestination(isPresented: $showResult) {
                if let result = model.result {
                    FolderDetailView(node: result.root, title: model.scannedFolderName, result: result)
                }
            }
            .onChange(of: model.isScanning) { _, scanning in
                if !scanning, model.result != nil, !model.cancelled { showResult = true }
            }
            .task { await model.loadFolders() }
            .sheet(isPresented: $showFolderPicker) {
                LocationBrowser(onSelect: { url in model.scanFolder(url) })
            }
        }
    }
}

struct ScanActivityView: View {
    let model: ScanModel
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ProgressView().controlSize(.large).tint(.indigo)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analyse läuft").font(.headline)
                        Text(model.scannedFolderName ?? "Ordner").foregroundStyle(.secondary)
                    }
                }
                Text(context.date.timeIntervalSince(model.lastUpdate) > 5
                     ? "Warten auf den Dateianbieter … Du kannst die Analyse abbrechen."
                     : "Dateien und Unterordner werden erfasst …")
                    .font(.subheadline).foregroundStyle(.secondary)
                let progress = model.progress ?? ScanProgress()
                LabeledContent("Dateien", value: progress.filesScanned.formatted())
                LabeledContent("Ordner", value: progress.directoriesScanned.formatted())
                LabeledContent("Erfasst", value: progress.bytesScanned.formattedBytes)
                LabeledContent("Laufzeit", value: context.date.timeIntervalSince(model.startedAt).formattedDuration)
                if !progress.currentPath.isEmpty {
                    Text(progress.currentPath).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                if progress.unreadableEntries > 0 {
                    Text("\(progress.unreadableEntries) nicht lesbare Einträge").font(.footnote)
                }
                Button("Analyse abbrechen", role: .cancel) { model.cancel() }
                    .buttonStyle(.bordered).controlSize(.large)
            }.padding(.vertical, 8)
        }
    }
}

struct FileRow: View {
    let name: String
    let isDirectory: Bool
    let fileCount: Int
    let bytes: Int64
    @Environment(\.dynamicTypeSize) private var typeSize
    init(node: FileNode) {
        name = node.name
        isDirectory = node.isDirectory
        fileCount = node.fileCount
        bytes = node.aggregateSize
    }
    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                FileRowLabel(name: name, isDirectory: isDirectory, fileCount: fileCount)
                Text(bytes.formattedBytes).font(.callout).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack {
                FileRowLabel(name: name, isDirectory: isDirectory, fileCount: fileCount)
                Spacer()
                Text(bytes.formattedBytes).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
struct FileRowLabel: View {
    let name: String
    let isDirectory: Bool
    let fileCount: Int
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                Text(isDirectory ? "\(fileCount) Dateien" : "Datei")
                    .font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: isDirectory ? "folder" : "doc")
                .foregroundStyle(isDirectory ? .indigo : .secondary)
        }
    }
}

final class FolderAccessLease: @unchecked Sendable {
    let url: URL
    let acquired: Bool
    init(url: URL) { self.url = url; acquired = url.startAccessingSecurityScopedResource() }
    deinit { if acquired { url.stopAccessingSecurityScopedResource() } }
}
