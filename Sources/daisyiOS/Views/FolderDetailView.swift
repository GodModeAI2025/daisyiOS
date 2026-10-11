import SwiftUI
import QuickLook

struct FolderDetailView: View {
    let node: FileNode
    @State private var query = ""
    @State private var previewURL: URL?
    var body: some View {
        List {
            Section {
                SunburstChart(root: node).frame(height: 280)
                LabeledContent("Dateien", value: node.fileCount.formatted())
                LabeledContent("Ordner", value: max(0, node.directoryCount - 1).formatted())
            }
            Section("Inhalt · nach Größe") {
                ForEach(node.children.sorted { $0.aggregateSize > $1.aggregateSize }.filter { query.isEmpty || $0.name.localizedStandardContains(query) }) { child in
                    FileEntry(node: child, previewURL: $previewURL)
                }
                if node.children.isEmpty {
                    ContentUnavailableView("Ordner ist leer", systemImage: "folder")
                }
            }
        }
        .navigationTitle(node.name)
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Dateien und Ordner suchen")
        .quickLookPreview($previewURL)
    }
}
struct FileEntry: View {
    let node: FileNode
    @Binding var previewURL: URL?
    var body: some View {
        if node.isDirectory {
            NavigationLink { FolderDetailView(node: node) } label: { FileRow(node: node) }
        } else {
            Button { previewURL = node.url } label: { FileRow(node: node) }.tint(.primary)
        }
    }
}
