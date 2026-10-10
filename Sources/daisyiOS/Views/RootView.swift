import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            OverviewView()
                .tabItem {
                    Label("Übersicht", systemImage: "internaldrive")
                }
            ScanPickerView()
                .tabItem {
                    Label("Scannen", systemImage: "magnifyingglass")
                }
        }
    }
}
