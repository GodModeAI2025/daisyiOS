#if DEBUG && os(macOS)
import SwiftUI

#Preview("OrbitDisk", traits: .fixedLayout(width: 1440, height: 900)) {
    NavigationSplitView {
        List {
            Section("Speicherorte") {
                Label("Ordner oder Datenträger wählen …", systemImage: "folder.badge.plus")
            }
            Section("Zuletzt analysiert") {
                Label("Studio", systemImage: "folder")
                Label("Projektarchiv", systemImage: "externaldrive")
            }
            Section {
                Text("Datenschutz").foregroundStyle(.link)
                Text("Support kontaktieren").foregroundStyle(.link)
            }
        }.navigationTitle("OrbitDisk")
            .navigationSplitViewColumnWidth(230)
    } detail: {
        NavigationStack { MacFolderView(result: storePreviewResult) }
    }.frame(width: 1440, height: 900).tint(.indigo)
}

@MainActor private var storePreviewResult: ScanResult {
    let root = URL(filePath: "/Volumes/Projektarchiv/Studio")
    let children: [FileNode] = [
        FileNode(name: "Filmprojekte", url: root.appendingPathComponent("Filmprojekte"), isDirectory: true, size: 0, aggregateSize: 14800000000, fileCount: 24, directoryCount: 1),
        FileNode(name: "Fotografie", url: root.appendingPathComponent("Fotografie"), isDirectory: true, size: 0, aggregateSize: 8600000000, fileCount: 186, directoryCount: 1),
        FileNode(name: "Design", url: root.appendingPathComponent("Design"), isDirectory: true, size: 0, aggregateSize: 4200000000, fileCount: 52, directoryCount: 1),
        FileNode(name: "Dokumente", url: root.appendingPathComponent("Dokumente"), isDirectory: true, size: 0, aggregateSize: 1200000000, fileCount: 34, directoryCount: 1),
        FileNode(name: "Präsentation.pdf", url: root.appendingPathComponent("Präsentation.pdf"), isDirectory: false, size: 24000000, aggregateSize: 24000000, fileCount: 1, directoryCount: 0)
    ]
    return ScanResult(root: FileNode(name: "Studio", url: root, isDirectory: true, size: 0, aggregateSize: 28824000000, fileCount: 297, directoryCount: 5, children: children), isAppContainer: false)
}
#endif
