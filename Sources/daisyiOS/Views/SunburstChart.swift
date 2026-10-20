import SwiftUI

struct RingSegment: Identifiable, Sendable {
    var id: UUID { node.id }
    let node: FileNode
    let start: Double
    let end: Double
    let depth: Int
    let colorIndex: Int
}

struct SunburstChart: View {
    let root: FileNode
    @Binding var selected: FileNode?
    var onOpenFolder: (FileNode) -> Void = { _ in }
    var onGoBack: (() -> Void)?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var cachedSegments: [RingSegment] = []
    @State private var preparing = true
    private static let palette: [Color] = [.indigo, .cyan, .pink, .teal, .orange, .purple]
    var body: some View {
        GeometryReader { proxy in
            let segments = cachedSegments
            ZStack {
                Circle().fill(.indigo.opacity(0.13)).blur(radius: 24).padding(25)
                ForEach(0..<3) { depth in
                    RingWedge(start: -.pi / 2, end: 3 * .pi / 2,
                              innerFraction: 0.39 + Double(depth) * 0.19,
                              outerFraction: 0.57 + Double(depth) * 0.19)
                        .fill(.secondary.opacity(0.12))
                }
                ForEach(segments) { segment in
                    let active = selected?.id == segment.node.id
                    RingWedge(start: segment.start, end: segment.end,
                              innerFraction: 0.39 + Double(segment.depth) * 0.19,
                              outerFraction: 0.57 + Double(segment.depth) * 0.19)
                        .fill(Self.palette[segment.colorIndex % Self.palette.count].gradient)
                        .overlay {
                            RingWedge(start: segment.start, end: segment.end,
                                      innerFraction: 0.39 + Double(segment.depth) * 0.19,
                                      outerFraction: 0.57 + Double(segment.depth) * 0.19)
                                .stroke(Color.orbitBackground.opacity(0.8), lineWidth: 2)
                        }
                        .opacity(selected == nil || active ? 1 : 0.45)
                        .scaleEffect(active && !reduceMotion ? 1.045 : 1)
                        .shadow(color: active ? Self.palette[segment.colorIndex % Self.palette.count].opacity(0.55) : .clear, radius: 12)
                        .accessibilityHidden(true)
                }
                VStack(spacing: 5) {
                    if preparing {
                        ProgressView().controlSize(.large)
                        Text("Diagramm wird aufgebaut …").font(.caption).multilineTextAlignment(.center)
                    } else {
                    Image(systemName: selected == nil ? "sparkles" : selected!.isDirectory ? "folder.fill" : "doc.fill")
                        .font(.title3).foregroundStyle(.indigo)
                    if !typeSize.isAccessibilitySize {
                        Text((selected ?? root).aggregateSize.formattedBytes)
                            .font(.headline).fontDesign(.rounded).contentTransition(reduceMotion ? .opacity : .numericText())
                        Text(onGoBack != nil ? "↑ Zurück" : selected == nil ? "Gesamt" : "Ausgewählt")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    }
                }.frame(width: min(proxy.size.width, proxy.size.height) * 0.35)
            }
            .task(id: "\(root.id)-\(root.aggregateSize)-\(root.fileCount)-\(root.directoryCount)-\(root.children.count)") {
                preparing = true
                let snapshot = root
                let worker = Task.detached(priority: .userInitiated) { Self.segments(for: snapshot) }
                let computed = await worker.value
                guard !Task.isCancelled else { return }
                cachedSegments = computed
                preparing = false
            }
            .contentShape(Rectangle())
            .onTapGesture { point in
                let dx = point.x - proxy.size.width / 2
                let dy = point.y - proxy.size.height / 2
                let radius = min(proxy.size.width, proxy.size.height) * 0.48
                let distance = hypot(dx, dy) / radius
                if distance < 0.35, let onGoBack { onGoBack(); return }
                var angle = atan2(dy, dx)
                if angle < -.pi / 2 { angle += 2 * .pi }
                let hit = segments.first {
                    distance >= 0.39 + Double($0.depth) * 0.19 && distance <= 0.57 + Double($0.depth) * 0.19 && angle >= $0.start && angle <= $0.end
                }?.node
                if let hit, hit.isDirectory { onOpenFolder(hit); return }
                withAnimation(reduceMotion ? .easeOut(duration: 0.15) : .spring(response: 0.42, dampingFraction: 0.76)) { selected = hit }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Speicherdiagramm")
            .accessibilityValue("\(root.aggregateSize.formattedBytes), \(root.fileCount) Dateien. Ordner antippen öffnet ihren Inhalt. Alle Einträge stehen in der Liste darunter.")
            .accessibilityActions {
                if let onGoBack { Button("Zur vorherigen Ansicht", action: onGoBack) }
            }
        }
    }
    nonisolated static func segments(for root: FileNode) -> [RingSegment] {
        var result: [RingSegment] = []
        func append(_ node: FileNode, start: Double, end: Double, depth: Int, color: Int?) {
            guard depth < 3 else { return }
            let children = node.children.filter { $0.aggregateSize > 0 }.sorted { $0.aggregateSize > $1.aggregateSize }
            let total = Double(max(node.aggregateSize, children.reduce(0) { $0 + $1.aggregateSize }))
            guard total > 0 else { return }
            var angle = start
            for (index, child) in children.enumerated() {
                let next = angle + (end - start) * Double(child.aggregateSize) / total
                let colorIndex = color ?? index
                if next - angle >= 0.02 {
                    result.append(RingSegment(node: child, start: angle, end: next, depth: depth, colorIndex: colorIndex))
                    append(child, start: angle, end: next, depth: depth + 1, color: colorIndex)
                }
                angle = next
            }
        }
        append(root, start: -.pi / 2, end: 3 * .pi / 2, depth: 0, color: nil)
        return result
    }
}


@Animatable
struct RingWedge: Shape {
    var start: Double
    var end: Double
    var innerFraction: Double
    var outerFraction: Double
    func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) * 0.48
        var path = Path()
        path.addArc(center: center, radius: radius * innerFraction, startAngle: .radians(start), endAngle: .radians(end), clockwise: false)
        path.addArc(center: center, radius: radius * outerFraction, startAngle: .radians(end), endAngle: .radians(start), clockwise: true)
        path.closeSubpath()
        return path
    }
}
