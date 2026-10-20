import SwiftUI

struct RootView: View {
    var body: some View {
        #if os(macOS)
        MacRootView().tint(.indigo)
        #else
        ScanPickerView().tint(.indigo)
        #endif
    }
}
#Preview { RootView() }
