import SwiftUI

struct OverviewView: View {
    @State private var volume: VolumeInfo?
    @State private var errorMessage: String?
    var body: some View {
        NavigationStack {
            List {
                if let volume {
                    Section {
                        StorageSummary(volume: volume)
                            .listRowBackground(Color.clear)
                    }
                    Section("Kapazität") {
                        LabeledContent("Gesamt", value: volume.totalCapacity.formattedBytes)
                        LabeledContent("Belegt", value: volume.usedCapacity.formattedBytes)
                        LabeledContent("Aktuell frei", value: volume.availableCapacity.formattedBytes)
                        LabeledContent("Für wichtige Daten verfügbar", value: volume.availableForImportantUsage.formattedBytes)
                    }
                    Section {
                        Label("Deine Daten bleiben auf dem Gerät", systemImage: "lock.shield")
                        Text("Analysiere eigene App-Daten oder einen freigegebenen Ordner aus Dateien. iOS schützt die Daten anderer Apps.")
                            .foregroundStyle(.secondary)
                    } header: { Text("Speicher verstehen") }
                    footer: { Text("Verfügbare Kapazität ist eine Systemschätzung und kann sich ändern. Für wichtige Daten kann iOS zusätzlich temporäre Daten freigeben.") }
                } else if let errorMessage {
                    ContentUnavailableView("Speicher nicht verfügbar", systemImage: "exclamationmark.triangle", description: Text(errorMessage))
                    Button("Erneut versuchen", action: load)
                } else { ProgressView("Speicher wird gelesen …") }
            }
            .navigationTitle("Speicher")
            .toolbar { Button("Aktualisieren", systemImage: "arrow.clockwise", action: load) }
            .refreshable { load() }
            .task { load() }
        }
    }
    private func load() {
        do { volume = try VolumeStatsService.internalVolume(); errorMessage = nil }
        catch { errorMessage = error.localizedDescription }
    }
}

struct StorageSummary: View {
    let volume: VolumeInfo
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Label("Gerätespeicher", systemImage: "internaldrive.fill")
                .font(.headline).foregroundStyle(.secondary)
            Text(volume.usedCapacity.formattedBytes)
                .font(.largeTitle.bold()).fontDesign(.rounded)
            Text("von \(volume.totalCapacity.formattedBytes) belegt")
                .foregroundStyle(.secondary)
            StorageBarView(volume: volume)
            HStack {
                Label("Belegt", systemImage: "circle.fill").foregroundStyle(.indigo)
                Spacer()
                Text("\(volume.availableCapacity.formattedBytes) frei")
            }.font(.subheadline)
        }.padding(.vertical, 12)
    }
}
struct StorageBarView: View {
    let volume: VolumeInfo
    var body: some View {
        GeometryReader { proxy in
            let fraction = min(1, max(0, Double(volume.usedCapacity) / Double(max(volume.totalCapacity, 1))))
            Capsule().fill(.quaternary)
                .overlay(alignment: .leading) {
                    Capsule().fill(.indigo.gradient).frame(width: proxy.size.width * fraction)
                }
        }
        .frame(height: 18)
        .accessibilityLabel("Speicherbelegung")
        .accessibilityValue("\(volume.usedCapacity.formattedBytes) von \(volume.totalCapacity.formattedBytes)")
    }
}
#Preview { OverviewView() }
