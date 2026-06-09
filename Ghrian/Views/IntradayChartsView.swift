import SwiftUI
import Charts
import GhrianKit

/// Intraday power (4 series, kW) + battery SOC strip, from `/intraday`.
struct IntradayChartsView: View {
    @Environment(AppModel.self) private var model
    let inverterID: Int

    @State private var series: IntradaySeries?
    @State private var loaded = false

    private static let powerColors: [String: Color] = [
        "PV": GhrianColor.pv, "Grid": GhrianColor.grid,
        "Load": GhrianColor.load, "Battery": GhrianColor.battery
    ]

    var body: some View {
        Card("Intraday", systemImage: "chart.xyaxis.line") {
            if let series, hasData(series) {
                powerChart(series.power)
                if let soc = series.socSeries, !soc.data.isEmpty {
                    socChart(soc)
                }
            } else {
                Text(loaded ? "No readings yet today. The chart fills in as data arrives."
                            : "Loading…")
                    .font(.callout)
                    .foregroundStyle(GhrianColor.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
        }
        .task(id: inverterID) {
            loaded = false
            series = await model.intraday(inverterID: inverterID, date: Date())
            loaded = true
        }
    }

    private func hasData(_ series: IntradaySeries) -> Bool {
        series.power.contains { !$0.data.isEmpty } || (series.socSeries.map { !$0.data.isEmpty } ?? false)
    }

    private func powerChart(_ power: [ChartSeries]) -> some View {
        Chart {
            ForEach(power) { series in
                ForEach(series.data) { point in
                    LineMark(
                        x: .value("Time", point.time),
                        y: .value("kW", point.value)
                    )
                    .foregroundStyle(by: .value("Series", series.name))
                    .lineStyle(StrokeStyle(lineWidth: 1.5))
                }
            }
        }
        .chartForegroundStyleScale(domain: Array(Self.powerColors.keys), range: Array(Self.powerColors.values))
        .chartLegend(position: .bottom, spacing: 8)
        .frame(height: 200)
    }

    private func socChart(_ soc: ChartSeries) -> some View {
        Chart(soc.data) { point in
            LineMark(x: .value("Time", point.time), y: .value("SOC", point.value))
                .foregroundStyle(GhrianColor.battery)
                .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartYScale(domain: 0...100)
        .chartYAxis { AxisMarks(values: [0, 50, 100]) }
        .frame(height: 90)
    }
}
