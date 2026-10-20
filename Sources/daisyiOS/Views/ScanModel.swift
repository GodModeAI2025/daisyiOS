import SwiftUI
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

