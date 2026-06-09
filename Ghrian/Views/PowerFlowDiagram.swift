import SwiftUI
import GhrianKit

/// Animated power-flow diagram: a central inverter hub with PV/Grid/Battery/Load
/// nodes at the corners and marching-ants flow lines. Mirrors the web SVG — active
/// flows animate (reversed for `.outgoing`), idle flows are faint.
struct PowerFlowDiagram: View {
    let flows: [Flow]

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            let hub = CGPoint(x: size.width / 2, y: size.height / 2)

            ZStack {
                TimelineView(.animation) { timeline in
                    Canvas { context, _ in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        for flow in flows {
                            var path = Path()
                            path.move(to: position(flow.key, in: size))
                            path.addLine(to: hub)
                            let color = GhrianColor.flow(flow.key)

                            if flow.isActive {
                                // Path runs node→hub; increasing dashPhase moves dashes
                                // toward the node, so .outgoing (hub→node) uses +t.
                                let speed = flow.direction == .outgoing ? t : -t
                                let phase = CGFloat(speed.truncatingRemainder(dividingBy: 1)) * 10
                                context.stroke(path, with: .color(color),
                                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [3, 7], dashPhase: phase))
                            } else {
                                context.stroke(path, with: .color(color.opacity(0.3)),
                                               style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                            }
                        }
                    }
                }

                hubView.position(hub)

                ForEach(flows) { flow in
                    nodeView(flow).position(position(flow.key, in: size))
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(minHeight: 240)
    }

    private var hubView: some View {
        ZStack {
            Circle().fill(GhrianColor.card)
            Circle().strokeBorder(GhrianColor.inverter, lineWidth: 2)
            Image(systemName: "cpu").foregroundStyle(GhrianColor.inverter)
        }
        .frame(width: 52, height: 52)
    }

    private func nodeView(_ flow: Flow) -> some View {
        let color = GhrianColor.flow(flow.key)
        return VStack(spacing: 3) {
            ZStack {
                Circle().fill(GhrianColor.card)
                Circle().strokeBorder(color, lineWidth: 2)
                Image(systemName: icon(flow.key)).foregroundStyle(color)
            }
            .frame(width: 46, height: 46)
            Text(GhrianFormat.kw(flow.kw))
                .font(.caption2.weight(.medium))
                .foregroundStyle(GhrianColor.textPrimary)
                .monospacedDigit()
        }
    }

    private func position(_ key: String, in size: CGSize) -> CGPoint {
        let fraction: (CGFloat, CGFloat) = switch key {
        case "pv": (0.20, 0.24)
        case "grid": (0.80, 0.24)
        case "battery": (0.20, 0.76)
        case "load": (0.80, 0.76)
        default: (0.5, 0.5)
        }
        return CGPoint(x: size.width * fraction.0, y: size.height * fraction.1)
    }

    private func icon(_ key: String) -> String {
        switch key {
        case "pv": "sun.max.fill"
        case "grid": "powerplug.fill"
        case "battery": "minus.plus.batteryblock.fill"
        case "load": "house.fill"
        default: "cpu"
        }
    }
}
