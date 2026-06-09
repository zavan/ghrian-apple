import SwiftUI
import GhrianKit

/// Circular battery state-of-charge gauge (matches the web `_battery_card`).
struct BatteryRing: View {
    let soc: Double?
    var size: CGFloat = 72

    var body: some View {
        let fraction = max(0, min(1, (soc ?? 0) / 100))
        ZStack {
            Circle().stroke(GhrianColor.cardBorder, lineWidth: 7)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(GhrianColor.battery, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 0) {
                Text(GhrianFormat.percent(soc))
                    .font(.headline)
                    .foregroundStyle(GhrianColor.textPrimary)
                    .monospacedDigit()
                Text("SOC")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.5)
                    .foregroundStyle(GhrianColor.textSecondary)
            }
        }
        .frame(width: size, height: size)
    }
}
