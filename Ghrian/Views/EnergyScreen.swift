import SwiftUI
import GhrianKit

/// Period energy + costs (Day/Month/Year/Lifetime) over `/energy`, plus the full intraday
/// charts. Honors the shared selection (per-inverter, or site-wide for "All").
struct EnergyScreen: View {
    @Environment(AppModel.self) private var model

    @State private var period: EnergyPeriod = .day
    @State private var report: EnergyReport?
    @State private var loading = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Picker("Period", selection: $period) {
                    ForEach(EnergyPeriod.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)

                Card(periodLabel, systemImage: "chart.bar.fill") {
                    if let report {
                        EnergyTotalsGrid(totals: report.totals)
                        if report.tariffConfigured {
                            CostCards(costs: report.costs, currency: report.currency)
                        }
                    } else {
                        Text(loading ? "Loading…" : "No data")
                            .font(.callout)
                            .foregroundStyle(GhrianColor.textSecondary)
                            .padding(.vertical, 8)
                    }
                }

                if let id = focusInverterID {
                    IntradayChartsView(inverterID: id)
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(GhrianColor.background)
        .navigationTitle("Energy")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .inverterToolbar()
        .task(id: "\(model.selection.storageValue)-\(period.rawValue)") {
            loading = true
            report = await model.energy(inverterID: model.selection.inverterID, period: period, date: Date())
            loading = false
        }
    }

    private var periodLabel: String { report?.label ?? period.title }

    /// The intraday endpoint is per-inverter; for "All" we chart the first inverter.
    private var focusInverterID: Int? {
        model.selection.inverterID ?? model.inverters.first?.id
    }
}

struct EnergyTotalsGrid: View {
    let totals: EnergyReport.Totals
    private let columns = [GridItem(.adaptive(minimum: 96), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 14) {
            MetricTile(value: GhrianFormat.kwh(totals.generation), label: "Generation", color: GhrianColor.pv)
            MetricTile(value: GhrianFormat.kwh(totals.selfConsumption), label: "Self-used", color: GhrianColor.load)
            MetricTile(value: GhrianFormat.kwh(totals.feedIn), label: "Exported", color: GhrianColor.grid)
            MetricTile(value: GhrianFormat.kwh(totals.import), label: "Imported", color: GhrianColor.importColor)
            MetricTile(value: GhrianFormat.kwh(totals.charge), label: "Charged", color: GhrianColor.battery)
            MetricTile(value: GhrianFormat.kwh(totals.discharge), label: "Discharged", color: GhrianColor.battery)
        }
    }
}

struct CostCards: View {
    let costs: EnergyReport.Costs
    let currency: String
    private let columns = [GridItem(.adaptive(minimum: 120), spacing: 12)]

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            costCard("Import cost", costs.importCost, GhrianColor.importColor, caption: "drawn from grid")
            costCard("Export earnings", costs.exportEarnings, GhrianColor.grid, caption: "fed to grid")
            costCard("Net", costs.net, costs.net < 0 ? GhrianColor.importColor : GhrianColor.battery, caption: "earnings − cost")
            costCard("Savings", costs.savings, GhrianColor.battery, caption: "self-consumed")
        }
    }

    private func costCard(_ title: String, _ amount: Double, _ color: Color, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased()).font(.caption2).tracking(0.5).foregroundStyle(GhrianColor.textSecondary)
            Text(GhrianFormat.money(amount, currency: currency))
                .font(.title3.weight(.semibold)).foregroundStyle(color).monospacedDigit()
            Text(caption).font(.caption2).foregroundStyle(GhrianColor.textSecondary.opacity(0.7))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(GhrianColor.background, in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(GhrianColor.cardBorder, lineWidth: 1))
    }
}
