#if os(macOS)
import SwiftUI

struct MacFolderView: View {
    let result: ScanResult
    var initialFolderURL: URL? = nil
    @State private var path: [URL] = []
    @State private var selected: FileNode?
    @State private var query = ""
    @State private var inspector = true
    @State private var batch = BatchSelection()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var current: FileNode { (path.last ?? initialFolderURL).flatMap { result.find($0) } ?? result.root }

    var body: some View {
        GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(current.url.path).font(.callout).foregroundStyle(.secondary).textSelection(.enabled)
                        if result.unreadableEntries > 0 {
                            Label("Unvollständig: \(result.unreadableEntries) Einträge nicht lesbar", systemImage: "exclamationmark.triangle")
                        }
                        let layout = geometry.size.width > 900 ? AnyLayout(HStackLayout(alignment: .top, spacing: 20)) : AnyLayout(VStackLayout(spacing: 20))
                        layout {
                            VStack(spacing: 16) {
                                SunburstChart(root: current, selected: $selected, onOpenFolder: open, onGoBack: path.isEmpty ? nil : { back() })
                                    .frame(height: 300)
                                Text("\(current.fileCount) Dateien · \(max(0, current.directoryCount - 1)) Ordner").monospacedDigit()
                                Text("Ordner im Orb öffnen die nächste Ebene. Die Mitte führt zurück. Grau zeigt sehr kleine Einträge und Ordnerbelegung.")
                                    .font(.callout).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity).cosmicCard()
                            FolderContents(node: current, result: result, query: query, selected: $selected, batch: batch, onOpenFolder: open)
                                .frame(maxWidth: .infinity)
                        }
                    }.padding(20)
                }.cosmicScreen()
            }
            .navigationTitle(current.name)
            .searchable(text: $query, prompt: "Dateien und Ordner suchen")
            .safeAreaInset(edge: .bottom) {
                if batch.count > 0 || batch.busy || batch.message != nil { BatchSelectionBar(selection: batch, result: result) }
            }
            .toolbar {
                Button(action: back) { Label("Eine Ebene zurück", systemImage: "chevron.backward") }.disabled(path.isEmpty)
                Menu {
                    NavigationLink { CleanupView(root: current, result: result) } label: { Label("Aufräumkandidaten finden", systemImage: "sparkles") }
                    NavigationLink { DuplicateView(root: current, result: result) } label: { Label("Duplikate finden", systemImage: "document.on.document") }
                } label: { Label("Ordner prüfen", systemImage: "sparkles") }
                Button { inspector.toggle() } label: { Label("Dateiaktionen", systemImage: "sidebar.trailing") }
            }
            .inspector(isPresented: $inspector) {
                ScrollView(.vertical, showsIndicators: true) {
                    FileActionPanel(node: selected.flatMap { result.find($0.url) } ?? current, result: result, isSelection: selected != nil, onOpenFolder: open, onDelete: { selected = nil })
                        .padding(12)
                }.inspectorColumnWidth(min: 250, ideal: 280, max: 360)
            }
    }
    private func open(_ folder: FileNode) {
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) {
            path.append(folder.url)
            selected = nil
            query = ""
            batch.clear()
        }
    }
    private func back() {
        guard !path.isEmpty else { return }
        path.removeLast()
        selected = nil
        query = ""
        batch.clear()
    }
}
#endif
