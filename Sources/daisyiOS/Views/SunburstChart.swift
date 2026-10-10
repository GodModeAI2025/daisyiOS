import SwiftUI

/// Minimal sunburst placeholder: renders the top level of the current node as a donut.
/// Phase 3: full port of OpenDisk's RingsChartView (hit-testing, zoom, breadcrumb).
struct SunburstChart: View {
    let root: FileNode
    @State private var path: [FileNode] = []

    private var current: FileNode {
        path.last ?? root
    }

    private static let palette: [Color] = [
        .blue, .teal, .indigo, .orange, .pink,
        .green, .purple, .mint, .cyan, .red
    ]

    var body: some View {
        Canvas { context, size in
            let children = current.children.sorted { $0.aggregateSize > $1.aggregateSize }
            guard !children.isEmpty else { return }

            let total = max(children.reduce(0) { $0 + $1.aggregateSize }, 1)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let innerRadius = min(size.width, size.height) * 0.25
            let outerRadius = min(size.width, size.height) * 0.48

            var startAngle = -Double.pi / 2
            for (index, child) in children.enumerated() {
                let sweep = (Double(child.aggregateSize) / Double(total)) * 2 * .pi
                let endAngle = startAngle + sweep

                var segment = Path()
                segment.addArc(
                    center: center,
                    radius: innerRadius,
                    startAngle: .radians(startAngle),
                    endAngle: .radians(endAngle),
                    clockwise: false
                )
                segment.addArc(
                    center: center,
                    radius: outerRadius,
                    startAngle: .radians(endAngle),
                    endAngle: .radians(startAngle),
                    clockwise: true
                )
                segment.closeSubpath()

                let color = Self.palette[index % Self.palette.count]
                context.fill(segment, with: .color(color.opacity(0.85)))
                startAngle = endAngle
            }
        }
        .contentShape(Rectangle())
        .overlay {
            VStack(spacing: 4) {
                Text(current.name)
                    .font(.headline)
                    .lineLimit(1)
                Text(current.aggregateSize.formattedBytes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .overlay(alignment: .topTrailing) {
            if !path.isEmpty {
                Button("Zurück") {
                    path.removeLast()
                }
                .font(.caption)
                .padding(6)
            }
        }
        .onTapGesture {
            if let largest = current.children.filter(\.isDirectory).max(by: { $0.aggregateSize < $1.aggregateSize }) {
                path.append(largest)
            }
        }
    }
}
