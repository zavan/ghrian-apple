import SwiftUI
import GhrianKit

/// Slate card container matching the web `.card`.
struct Card<Content: View>: View {
    var title: String?
    var systemImage: String?
    @ViewBuilder var content: Content

    init(_ title: String? = nil, systemImage: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                Label {
                    Text(title)
                } icon: {
                    if let systemImage { Image(systemName: systemImage) }
                }
                .font(.subheadline)
                .foregroundStyle(GhrianColor.textSecondary)
            }
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GhrianColor.card, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(GhrianColor.cardBorder, lineWidth: 1))
    }
}

/// A value + uppercase label, used across the energy grids.
struct MetricTile: View {
    let value: String
    let label: String
    var color: Color = GhrianColor.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.headline)
                .foregroundStyle(color)
                .monospacedDigit()
            Text(label.uppercased())
                .font(.caption2)
                .tracking(0.5)
                .foregroundStyle(GhrianColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A status pill that floats in Liquid Glass, tinted by the inverter's status color.
struct StatusBadge: View {
    let status: InverterStatus

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(0.5)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundStyle(GhrianColor.status(status))
            .glassEffect(.regular.tint(GhrianColor.status(status).opacity(0.25)), in: .capsule)
    }
}

/// A small pulsing dot for "live" affordances (a ring expands and fades outward).
struct PulsingDot: View {
    var color: Color
    @State private var animating = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(color, lineWidth: 1.5)
                    .scaleEffect(animating ? 2.4 : 1)
                    .opacity(animating ? 0 : 0.7)
            )
            .animation(.easeOut(duration: 1.6).repeatForever(autoreverses: false), value: animating)
            .onAppear { animating = true }
    }
}

extension InverterStatus {
    var symbol: String {
        switch self {
        case .online: "bolt.fill"
        case .offline: "bolt.slash.fill"
        case .unknown: "questionmark"
        }
    }
}
