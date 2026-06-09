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

struct StatusBadge: View {
    let status: InverterStatus

    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(0.5)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(GhrianColor.status(status).opacity(0.2), in: Capsule())
            .foregroundStyle(GhrianColor.status(status))
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
