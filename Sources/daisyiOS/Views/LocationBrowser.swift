#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers

/// System Files browser. directoryURL is a starting-location hint, not a reveal API.
struct LocationBrowser: UIViewControllerRepresentable {
    var startingDirectory: URL?
    var onSelect: ((URL) -> Void)?
    @Environment(\.dismiss) private var dismiss
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let controller = UIDocumentPickerViewController(forOpeningContentTypes: onSelect == nil ? [.item, .folder] : [.folder], asCopy: false)
        controller.directoryURL = startingDirectory
        controller.allowsMultipleSelection = false
        controller.shouldShowFileExtensions = true
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: UIDocumentPickerViewController, context: Context) {}
    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: LocationBrowser
        init(parent: LocationBrowser) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first { parent.onSelect?(url) }
            parent.dismiss()
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { parent.dismiss() }
    }
}

#endif
