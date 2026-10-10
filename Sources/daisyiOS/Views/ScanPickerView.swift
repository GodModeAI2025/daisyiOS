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

    private var scanTask: Task<Void, Never>?
    private var accessURL: URL?

    func scanAppContainer() {
        guard !isScanning else { return }
        let container = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        startScan(of: container, folderName: "App-Container")
    }

    func scanFolder(_ url: URL) {
        guard !isScanning else { return }
        let _ = url.startAccessingSecurityScopedResource()
        accessURL = url
        startScan(of: url, folderName: url.lastPathComponent)
    }

    func cancel() {
        scanTask?.cancel()
    }

    private func startScan(of url: URL, folderName: String) {
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
                case .failed(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
            self?.finishScan()
        }
    }

    private func finishScan() {
        accessURL?.stopAccessingSecurityScopedResource()
        accessURL = nil
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

                if let root = model.root {
                    Section("Ergebnis (\(model.scannedFolderName ?? root.name))") {
                        SunburstChart(root: root)
                            .frame(height: 260)
                        ForEach(root.children) { child in
                            FileRow(node: child)
                        }
                    }
                }
            }
            .navigationTitle("Scannen")
            .fileImporter(
                isPresented: $showFolderPicker,
                allowedContentTypes: [.folder],
                allowsMultipleSelection: false
            ) { result in
                if case let .success(urls) = result, let url = urls.first {
                    model.scanFolder(url)
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
