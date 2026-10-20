import SwiftUI

@main
struct daisyiOSApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        #if os(macOS)
        .commands { MacCommands() }
        .defaultSize(width: 1200, height: 800)
        .windowResizability(.contentMinSize)
        #endif
    }
}

#Preview {
    RootView()
}
