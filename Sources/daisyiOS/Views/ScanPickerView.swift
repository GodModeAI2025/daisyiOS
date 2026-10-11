import SwiftUI
import UniformTypeIdentifiers
import Observation

@MainActor
@Observable
final class ScanModel {
    var progress: ScanProgress?
    var root: FileNode?
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
        root = nil
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
                    self.root = node
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
                Section("Scannen") {
                    Button {
                        model.scanAppContainer()
                    } label: {
                        Label("Eigene App-Daten", systemImage: "shippingbox")
                    }
                    .disabled(model.isScanning)

                    Button {
                        showFolderPicker = true
                    } label: {
                        Label("Ordner wählen…", systemImage: "folder.badge.plus")
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
                if let root = model.root {
                    Section("Ergebnis") {
                        NavigationLink {
                            FolderDetailView(node: root)
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
            .navigationTitle("Analysieren")
            .task { await model.loadFolders() }
            .fileImporter(
                isPresented: $showFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls): if let url = urls.first { model.scanFolder(url) }
                case .failure(let error): model.errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct FileRow: View {
    let node: FileNode

    var body: some View {
        HStack {
            Image(systemName: node.isDirectory ? "folder" : "doc")
                .foregroundStyle(node.isDirectory ? .blue : .secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(node.name)
                Text("\(node.fileCount) Dateien")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(node.aggregateSize.formattedBytes)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }
}

final class FolderAccessLease {
    let url: URL
    let acquired: Bool
    init(url: URL) { self.url = url; acquired = url.startAccessingSecurityScopedResource() }
    deinit { if acquired { url.stopAccessingSecurityScopedResource() } }
}
