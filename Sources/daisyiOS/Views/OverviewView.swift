import SwiftUI

struct OverviewView: View {
    @State private var volume: VolumeInfo?
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            List {
                if let volume {
                    Section("Speicher") {
                        StorageBarView(volume: volume)
                        LabeledContent("Gesamt", value: volume.totalCapacity.formattedBytes)
                        LabeledContent("Belegt", value: volume.usedCapacity.formattedBytes)
                        LabeledContent("Frei", value: volume.availableCapacity.formattedBytes)
                        LabeledContent("Wiederverwendbar", value: volume.purgeableCapacity.formattedBytes)
                    }
                    Section {
                        Text(volume.name)
                            .font(.headline)
                    }
                } else if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                } else {
                    Section {
                        ProgressView()
                    }
                }
            }
            .navigationTitle("Speicher")
            .task {
                load()
            }
        }
    }

    private func load() {
        do {
            volume = try VolumeStatsService.internalVolume()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct StorageBarView: View {
    let volume: VolumeInfo

    var body: some View {
        GeometryReader { proxy in
            let total = Double(max(volume.totalCapacity, 1))
            let used = Double(volume.usedCapacity) / total
            let purgeable = Double(volume.purgeableCapacity) / total

            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.blue)
                    .frame(width: max(0, proxy.size.width * used))
                RoundedRectangle(cornerRadius: 4)
                    .fill(.teal.opacity(0.5))
                    .frame(width: max(0, proxy.size.width * purgeable))
                Spacer(minLength: 0)
            }
        }
        .frame(height: 18)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
