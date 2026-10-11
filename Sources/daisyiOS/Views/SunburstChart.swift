import SwiftUI

struct RingSegment: Identifiable {
    var id: UUID { node.id }
    let node: FileNode
    let start: Double
    let end: Double
    let depth: Int
    let colorIndex: Int
}

struct SunburstChart: View {
    let root: FileNode
    @State private var selected: FileNode?
    private static let palette: [Color] = [.indigo, .teal, .orange, .pink, .blue, .purple]
    var body: some View {
        GeometryReader { proxy in
            let segments = Self.segments(for: root)
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) * 0.48
                for segment in segments {
                    let inner = radius * (0.39 + Double(segment.depth) * 0.19)
                    let outer = inner + radius * 0.18
                    var path = Path()
                    path.addArc(center: center, radius: inner, startAngle: .radians(segment.start), endAngle: .radians(segment.end), clockwise: false)
                    path.addArc(center: center, radius: outer, startAngle: .radians(segment.end), endAngle: .radians(segment.start), clockwise: true)
                    path.closeSubpath()
                    context.fill(path, with: .color(Self.palette[segment.colorIndex % Self.palette.count].opacity(1 - Double(segment.depth) * 0.18)))
                    context.stroke(path, with: .color(Color(uiColor: .systemBackground)), lineWidth: 2)
                }
            }
            .overlay {
                VStack(spacing: 4) {
                    Text(root.aggregateSize.formattedBytes).font(.title3.bold()).fontDesign(.rounded)
                    Text("\(root.fileCount) Dateien").font(.caption).foregroundStyle(.secondary)
                }.frame(width: min(proxy.size.width, proxy.size.height) * 0.35)
            }
            .contentShape(Rectangle())
            .onTapGesture { point in
                let dx = point.x - proxy.size.width / 2
                let dy = point.y - proxy.size.height / 2
                let radius = min(proxy.size.width, proxy.size.height) * 0.48
                let distance = hypot(dx, dy) / radius
                var angle = atan2(dy, dx)
                if angle < -.pi / 2 { angle += 2 * .pi }
                selected = segments.first {
                    distance >= 0.39 + Double($0.depth) * 0.19 && distance <= 0.57 + Double($0.depth) * 0.19 && angle >= $0.start && angle <= $0.end
                }?.node
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Speicherdiagramm")
            .accessibilityValue("\(root.aggregateSize.formattedBytes), \(root.fileCount) Dateien. Alle Einträge stehen in der Liste darunter.")
        }
        .sheet(item: $selected) { node in
            NavigationStack {
                if node.isDirectory {
                    FolderDetailView(node: node).toolbar { Button("Fertig") { selected = nil } }
                } else {
                    List {
                        LabeledContent("Name", value: node.name)
                        LabeledContent("Speicherbedarf", value: node.aggregateSize.formattedBytes)
                    }.navigationTitle("Datei").toolbar { Button("Fertig") { selected = nil } }
                }
            }
        }
    }
    static func segments(for root: FileNode) -> [RingSegment] {
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
                result.append(RingSegment(node: child, start: angle, end: next, depth: depth, colorIndex: colorIndex))
                append(child, start: angle, end: next, depth: depth + 1, color: colorIndex)
                angle = next
            }
        }
        append(root, start: -.pi / 2, end: 3 * .pi / 2, depth: 0, color: nil)
        return result
    }
}
