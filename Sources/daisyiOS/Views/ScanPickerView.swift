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

    func loadFolders() async { savedFolders = await AccessStore.shared.folders }

    func reopen(_ folder: AccessStore.Folder) async {
        do { scanFolder(try await AccessStore.shared.url(for: folder)) }
        catch { errorMessage = "Ordner nicht mehr verfügbar. Bitte erneut auswählen. " + error.localizedDescription }
    }

    private var scanTask: Task<Void, Never>?
    private var accessURL: URL?
    private var accessLease: FolderAccessLease?

    func scanAppContainer() {
        guard !isScanning else { return }
        accessLease = nil
        accessURL = nil
        let container = URL(fileURLWithPath: NSHomeDirectory())
        startScan(of: container, folderName: "App-Container")
    }

    func scanFolder(_ url: URL) {
        guard !isScanning else { return }
        accessLease = FolderAccessLease(url: url)
        accessURL = url
        startScan(of: url, folderName: url.lastPathComponent)
    }

    func cancel() {
        cancelled = true
        scanTask?.cancel()
    }

    private func startScan(of url: URL, folderName: String) {
        cancelled = false
        isScanning = true
        progress = ScanProgress()
        result = nil
        errorMessage = nil
        scannedFolderName = folderName

        scanTask = Task { [weak self] in
            let engine = ScanEngine()
            for await event in await engine.scan(url) {
                guard let self else { return }
                switch event {
                case .progress(let progress):
                    self.progress = progress
                case .finished(let node):
                    self.result = ScanResult(root: node, isAppContainer: url.standardizedFileURL == URL(fileURLWithPath: NSHomeDirectory()).standardizedFileURL, accessLease: self.accessLease)
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
            self?.finishScan()
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

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("DEIN DIGITALER KOSMOS", systemImage: "sparkles").font(.caption.weight(.semibold)).foregroundStyle(.indigo)
                        Text("Finde, was Raum braucht.").font(.title.bold()).fontDesign(.rounded)
                        Text("Ein Ordner. Ein Laufwerk. Eine neue Perspektive auf deine Daten.").foregroundStyle(.secondary)
                    }.padding(.vertical, 12).listRowBackground(Color.clear)
                }
                Section("Analyse starten") {
                    Button {
                        model.scanAppContainer()
                    } label: {
                        Label("Eigene App-Daten", systemImage: "shippingbox")
                    }
                    .disabled(model.isScanning)

                    Button {
                        showFolderPicker = true
                    } label: {
                        Label("Ordner oder Datenträger wählen", systemImage: "externaldrive.badge.plus")
                    }
                    .disabled(model.isScanning)
                }

                if model.isScanning, let progress = model.progress {
                    Section("Fortschritt") {
                        ProgressView("Ordner wird analysiert …")
                        LabeledContent("Dateien", value: "\(progress.filesScanned)")
                        LabeledContent("Ordner", value: "\(progress.directoriesScanned)")
                        LabeledContent("Gelesen", value: progress.bytesScanned.formattedBytes)
                        LabeledContent("Zeit", value: progress.elapsed.formattedDuration)
                        Button("Abbrechen", role: .cancel) {
                            model.cancel()
                        }
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
                    Label("Lokal und privat", systemImage: "lock.shield")
                    Text("Wähle einen Ordner auf deinem Gerät, in iCloud Drive oder auf einem verbundenen Laufwerk. Bei Cloud-Dateien kann das Laden Zeit benötigen.")
                        .foregroundStyle(.secondary)
                }

            }
            .cosmicScreen()
            .navigationTitle("Entdecken")
            .task { await model.loadFolders() }
            .sheet(isPresented: $showFolderPicker) {
                LocationBrowser(onSelect: { url in model.scanFolder(url) })
            }
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

final class FolderAccessLease {
    let url: URL
    let acquired: Bool
    init(url: URL) { self.url = url; acquired = url.startAccessingSecurityScopedResource() }
    deinit { if acquired { url.stopAccessingSecurityScopedResource() } }
}
