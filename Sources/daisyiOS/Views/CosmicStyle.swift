import SwiftUI

struct CosmicBackdrop: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        ZStack {
            Color.orbitBackground
            RadialGradient(colors: [.indigo.opacity(scheme == .dark ? 0.32 : 0.14), .clear], center: .topLeading, startRadius: 0, endRadius: 650)
            RadialGradient(colors: [.cyan.opacity(scheme == .dark ? 0.16 : 0.10), .clear], center: .bottomTrailing, startRadius: 0, endRadius: 500)
        }.ignoresSafeArea().accessibilityHidden(true)
    }
}
struct CosmicCard: ViewModifier {
    func body(content: Content) -> some View {
        content.padding(20)
            .background(Color.orbitCard.opacity(0.92), in: RoundedRectangle(cornerRadius: 28))
            .overlay { RoundedRectangle(cornerRadius: 28).stroke(LinearGradient(colors: [.indigo.opacity(0.4), .cyan.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1) }
    }
}
extension View {
    func cosmicCard() -> some View { modifier(CosmicCard()) }
    func cosmicScreen() -> some View {
        scrollContentBackground(.hidden).background { CosmicBackdrop() }
    }
}

struct OrbitActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    var prominent = false
    func makeBody(configuration: Configuration) -> some View {
        let destructive = configuration.role == .destructive
        let tint: Color = destructive ? .red : .indigo
        configuration.label
            .font(.body.weight(.medium))
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .foregroundStyle(prominent ? .white : tint)
            .background(prominent ? tint : tint.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).stroke(tint.opacity(prominent ? 0 : 0.16), lineWidth: 1) }
            .contentShape(Rectangle())
            .opacity(enabled ? (configuration.isPressed ? 0.7 : 1) : 0.4)
    }
}
struct OrbitOptionLabel: View {
    let title: String
    let value: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbol).foregroundStyle(.indigo)
                Text(title).foregroundStyle(.secondary)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down").foregroundStyle(.secondary)
            }.font(.caption)
            Text(value).font(.body.weight(.medium)).foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }.padding(14)
            .background(Color.orbitControl, in: RoundedRectangle(cornerRadius: 14))
            .contentShape(Rectangle())
    }
}

extension Color {
    static var orbitBackground: Color {
        #if os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(uiColor: .systemGroupedBackground)
        #endif
    }
    static var orbitCard: Color {
        #if os(macOS)
        Color(nsColor: .controlBackgroundColor)
        #else
        Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }
    static var orbitControl: Color {
        #if os(macOS)
        Color(nsColor: .controlColor)
        #else
        Color(uiColor: .tertiarySystemGroupedBackground)
        #endif
    }
}
