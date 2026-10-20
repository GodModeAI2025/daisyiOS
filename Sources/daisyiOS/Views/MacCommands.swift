#if os(macOS)
import SwiftUI

private struct FolderPickerKey: FocusedValueKey {
    typealias Value = Binding<Bool>
}
extension FocusedValues {
    var folderPicker: Binding<Bool>? {
        get { self[FolderPickerKey.self] }
        set { self[FolderPickerKey.self] = newValue }
    }
}
struct MacCommands: Commands {
    @FocusedValue(\.folderPicker) private var folderPicker
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Ordner oder Datenträger öffnen …") { folderPicker?.wrappedValue = true }
                .keyboardShortcut("o").disabled(folderPicker == nil)
        }
        CommandGroup(replacing: .help) {
            Link("OrbitDisk Support", destination: URL(string: "mailto:info@mobilebox-consulting.de")!)
        }
    }
}
#endif
