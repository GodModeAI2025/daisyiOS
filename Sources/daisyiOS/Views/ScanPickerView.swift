#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers
import Observation

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

#endif
