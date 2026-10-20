#if os(macOS)
import SwiftUI
import UniformTypeIdentifiers

struct MacRootView: View {
    @State private var model = ScanModel()
    @State private var choosingFolder = false
    @State private var dropTargeted = false

    var body: some View {
        NavigationSplitView {
            List {
                Section("Speicherorte") {
                    Button { choosingFolder = true } label: {
                        Label("Ordner oder Datenträger wählen …", systemImage: "folder.badge.plus")
                    }.disabled(model.isScanning)
                }
                Section("Zuletzt analysiert") {
                    ForEach(model.savedFolders) { folder in
                        Button { Task { await model.reopen(folder) } } label: {
                            Label(folder.name, systemImage: "folder")
                        }.disabled(model.isScanning)
                    }
                }
                Section {
                    Link("Datenschutz", destination: URL(string: "https://www.mobilebox-consulting.de/datenschutzerkl%C3%A4rung-privacy-policy/")!)
                    Link("Support kontaktieren", destination: URL(string: "mailto:info@mobilebox-consulting.de")!)
                }
            }.navigationTitle("OrbitDisk")
                .navigationSplitViewColumnWidth(min: 200, ideal: 230, max: 300)
        } detail: {
            if model.isScanning {
                ScanActivityView(model: model).padding(32).frame(maxWidth: .infinity, maxHeight: .infinity).cosmicScreen()
            } else if let result = model.result {
                NavigationStack { MacFolderView(result: result).id(result.root.id) }
            } else {
                VStack(spacing: 24) {
                    Image(systemName: "circle.hexagongrid.fill").font(.system(size: 68)).foregroundStyle(.indigo.gradient)
                    Text("Dein Speicher. Neue Perspektiven.").font(.largeTitle.bold()).fontDesign(.rounded)
                    Text("Ziehe einen Ordner oder Datenträger hierher, um seinen Speicherbedarf zu entdecken.")
                        .font(.title3).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Ordner oder Datenträger wählen …") { choosingFolder = true }
                        .buttonStyle(.borderedProminent).controlSize(.large)
                    Text("Nur freigegebene Ordner werden analysiert. Alles bleibt auf deinem Mac.")
                        .foregroundStyle(.secondary)
                }.padding(40).frame(maxWidth: .infinity, maxHeight: .infinity).cosmicScreen()
            }
        }
        .frame(minWidth: 900, minHeight: 650)
        .toolbar {
            Button { choosingFolder = true } label: { Label("Ordner öffnen", systemImage: "folder.badge.plus") }
                .disabled(model.isScanning)
        }
        .focusedSceneValue(\.folderPicker, model.isScanning ? nil : $choosingFolder)
        .fileImporter(isPresented: $choosingFolder, allowedContentTypes: [.folder]) { selection in
            switch selection {
            case .success(let url): model.scanFolder(url)
            case .failure(let error): model.errorMessage = error.localizedDescription
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            guard !model.isScanning, urls.count == 1, let url = urls.first, url.isFileURL else { return false }
            model.scanFolder(url)
            return true
        } isTargeted: { dropTargeted = $0 }
        .overlay { if dropTargeted { RoundedRectangle(cornerRadius: 12).stroke(.indigo, lineWidth: 3).allowsHitTesting(false) } }
        .alert("Ordner nicht verfügbar", isPresented: Binding(get: { model.errorMessage != nil }, set: { if !$0 { model.errorMessage = nil } })) {
            Button("OK") { model.errorMessage = nil }
        } message: { Text(model.errorMessage ?? "") }
        .task { await model.loadFolders() }
    }
}
#endif
