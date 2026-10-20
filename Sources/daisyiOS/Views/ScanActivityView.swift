import SwiftUI

struct ScanActivityView: View {
    let model: ScanModel
    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ProgressView().controlSize(.large).tint(.indigo)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analyse läuft").font(.headline)
                        Text(model.scannedFolderName ?? "Ordner").foregroundStyle(.secondary)
                    }
                }
                Text(context.date.timeIntervalSince(model.lastUpdate) > 5
                     ? "Warten auf den Dateianbieter … Du kannst die Analyse abbrechen."
                     : "Dateien und Unterordner werden erfasst …")
                    .font(.subheadline).foregroundStyle(.secondary)
                    #if os(macOS)
                    .lineLimit(2, reservesSpace: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    #endif
                let progress = model.progress ?? ScanProgress()
                LabeledContent("Dateien", value: progress.filesScanned.formatted())
                LabeledContent("Ordner", value: progress.directoriesScanned.formatted())
                LabeledContent("Erfasst", value: progress.bytesScanned.formattedBytes)
                LabeledContent("Laufzeit", value: context.date.timeIntervalSince(model.startedAt).formattedDuration)
                #if os(macOS)
                Text(progress.currentPath).font(.caption).foregroundStyle(.secondary)
                    .lineLimit(2, reservesSpace: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("\(progress.unreadableEntries) nicht lesbare Einträge").font(.footnote)
                #else
                if !progress.currentPath.isEmpty {
                    Text(progress.currentPath).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                }
                if progress.unreadableEntries > 0 {
                    Text("\(progress.unreadableEntries) nicht lesbare Einträge").font(.footnote)
                }
                #endif
                Button("Analyse abbrechen", role: .cancel) { model.cancel() }
                    .buttonStyle(.bordered).controlSize(.large)
            }.padding(.vertical, 8)
                #if os(macOS)
                .monospacedDigit()
                .frame(width: 440, alignment: .leading)
                #endif
        }
    }
}

struct FileRow: View {
    let name: String
    let isDirectory: Bool
    let fileCount: Int
    let bytes: Int64
    @Environment(\.dynamicTypeSize) private var typeSize
    init(node: FileNode) {
        name = node.name
        isDirectory = node.isDirectory
        fileCount = node.fileCount
        bytes = node.aggregateSize
    }
    var body: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                FileRowLabel(name: name, isDirectory: isDirectory, fileCount: fileCount)
                Text(bytes.formattedBytes).font(.callout).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity, alignment: .leading)
        } else {
            HStack {
                FileRowLabel(name: name, isDirectory: isDirectory, fileCount: fileCount)
                Spacer()
                Text(bytes.formattedBytes).font(.callout).foregroundStyle(.secondary)
            }
        }
    }
}
struct FileRowLabel: View {
    let name: String
    let isDirectory: Bool
    let fileCount: Int
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                Text(isDirectory ? "\(fileCount) Dateien" : "Datei")
                    .font(.caption).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: isDirectory ? "folder" : "doc")
                .foregroundStyle(isDirectory ? .indigo : .secondary)
        }
    }
}

final class FolderAccessLease: @unchecked Sendable {
    let url: URL
    let acquired: Bool
    init(url: URL) { self.url = url; acquired = url.startAccessingSecurityScopedResource() }
    deinit { if acquired { url.stopAccessingSecurityScopedResource() } }
}

