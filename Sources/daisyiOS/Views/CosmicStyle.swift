import SwiftUI

struct CosmicBackdrop: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
            RadialGradient(colors: [.indigo.opacity(scheme == .dark ? 0.32 : 0.14), .clear], center: .topLeading, startRadius: 0, endRadius: 650)
            RadialGradient(colors: [.cyan.opacity(scheme == .dark ? 0.16 : 0.10), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 500)
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}
struct CosmicCard: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(20)
            .background(Color(uiColor: .secondarySystemGroupedBackground).opacity(0.92), in: RoundedRectangle(cornerRadius: 28))
            .overlay { RoundedRectangle(cornerRadius: 28).stroke(LinearGradient(colors: [.indigo.opacity(0.4), .cyan.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) }
    }
}
extension View {
    func cosmicCard() -> some View { modifier(CosmicCard()) }
    func cosmicScreen() -> some View {
        scrollContentBackground(.hidden).background { CosmicBackdrop() }
    }
}
