import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Übersicht", systemImage: "internaldrive") { OverviewView() }
            Tab("Analysieren", systemImage: "chart.pie") { ScanPickerView() }
        }.tint(.indigo)
    }
}
#Preview { RootView() }
