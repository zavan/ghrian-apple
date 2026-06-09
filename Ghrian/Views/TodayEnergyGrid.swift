import SwiftUI
import GhrianKit

/// Six daily-energy metrics (matches the web `_today_energy`).
struct TodayEnergyGrid: View {
    let today: TodayEnergy

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        Card("Today", systemImage: "calendar") {
            LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
                MetricTile(value: GhrianFormat.kwh(today.generation), label: "Yield", color: GhrianColor.pv)
                MetricTile(value: GhrianFormat.kwh(today.charge), label: "Charge", color: GhrianColor.battery)
                MetricTile(value: GhrianFormat.kwh(today.discharge), label: "Discharge", color: GhrianColor.battery)
                MetricTile(value: GhrianFormat.kwh(today.toGrid), label: "To Grid", color: GhrianColor.grid)
                MetricTile(value: GhrianFormat.kwh(today.fromGrid), label: "From Grid", color: GhrianColor.importColor)
                MetricTile(value: GhrianFormat.kwh(today.consumption), label: "Consumption", color: GhrianColor.load)
            }
        }
    }
}
