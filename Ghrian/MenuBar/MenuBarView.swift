#if os(macOS)
import SwiftUI
import GhrianKit

/// The macOS menu-bar popover: a compact live dashboard (switchable inverter →
/// power flow + today totals + intraday charts). Shares the app's polling model.
struct MenuBarView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            header(model: $model)
            Divider().overlay(GhrianColor.cardBorder)

            ScrollView {
                VStack(spacing: 12) {
                    if model.inverters.isEmpty {
                        Text(model.isConnected ? "Loading…" : "Not connected. Open the app to set up.")
                            .foregroundStyle(GhrianColor.textSecondary)
                            .padding(.vertical, 24)
                    } else {
                        PowerFlowDiagram(flows: model.combined.flows)
                            .frame(height: 220)
                        HStack(spacing: 12) {
                            BatteryRing(soc: model.combined.batterySoc, size: 60)
                            todaySummary
                        }
                        if let id = focusInverterID {
                            IntradayChartsView(inverterID: id)
                        }
                    }
                }
                .padding(12)
            }
        }
        .background(GhrianColor.background)
        .task {
            if model.isConnected { await model.load() }
        }
    }

    private func header(model: Bindable<AppModel>) -> some View {
        HStack {
            if model.wrappedValue.inverters.count > 1 {
                Picker("", selection: model.selection) {
                    Text("All").tag(InverterSelection.all)
                    ForEach(model.wrappedValue.inverters) { inverter in
                        Text(inverter.name).tag(InverterSelection.inverter(inverter.id))
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .fixedSize()
            } else {
                Label("ghrian", systemImage: "sun.max.fill")
                    .foregroundStyle(GhrianColor.inverter)
            }
            Spacer()
            Button { Task { await model.wrappedValue.load() } } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.borderless)
            Button { NSApp.terminate(nil) } label: { Image(systemName: "power") }
                .buttonStyle(.borderless)
        }
        .padding(10)
    }

    private var todaySummary: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("Yield", GhrianFormat.kwh(model.combined.today.generation), GhrianColor.pv)
            row("Consumption", GhrianFormat.kwh(model.combined.today.consumption), GhrianColor.load)
            row("To Grid", GhrianFormat.kwh(model.combined.today.toGrid), GhrianColor.grid)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func row(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label).font(.caption).foregroundStyle(GhrianColor.textSecondary)
            Spacer()
            Text(value).font(.caption.weight(.medium)).foregroundStyle(color).monospacedDigit()
        }
    }

    private var focusInverterID: Int? {
        model.selection.inverterID ?? model.inverters.first?.id
    }
}

/// The menu-bar title: a small icon + the current PV output.
struct MenuBarLabel: View {
    let model: AppModel

    var body: some View {
        let pv = model.combined.pv
        Image(systemName: "sun.max.fill")
        if pv.isActive {
            Text(GhrianFormat.kw(pv.kw))
        }
    }
}
#endif
