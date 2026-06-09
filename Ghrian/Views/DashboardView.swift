import SwiftUI
import GhrianKit

struct DashboardView: View {
    @Environment(AppModel.self) private var model
    @State private var showSettings = false

    var body: some View {
        @Bindable var model = model

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if model.inverters.isEmpty {
                        emptyState
                    } else {
                        if model.inverters.count > 1 {
                            selectionPicker(model: $model)
                        }
                        LiveOverviewCard(combined: model.combined,
                                         title: selectionTitle,
                                         status: selectionStatus)
                        TodayEnergyGrid(today: model.combined.today)
                        if let focusID = focusInverterID {
                            IntradayChartsView(inverterID: focusID)
                        }
                        EnergySection(inverterID: model.selection.inverterID)
                    }

                    if let error = model.errorMessage {
                        Text(error).font(.callout).foregroundStyle(GhrianColor.offline)
                    }
                }
                .padding(16)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(GhrianColor.background)
            .navigationTitle("ghrian")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showSettings = true } label: { Image(systemName: "gearshape") }
                }
                ToolbarItem(placement: .automatic) {
                    Button { Task { await model.load() } } label: { Image(systemName: "arrow.clockwise") }
                        .disabled(model.isLoading)
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationStack { SettingsView() }
            }
        }
        .task { await model.load() }
    }

    private func selectionPicker(model: Bindable<AppModel>) -> some View {
        Picker("Inverter", selection: model.selection) {
            Text("All").tag(InverterSelection.all)
            ForEach(model.wrappedValue.inverters) { inverter in
                Text(inverter.name).tag(InverterSelection.inverter(inverter.id))
            }
        }
        .pickerStyle(.segmented)
    }

    private var selectionTitle: String {
        switch model.selection {
        case .all: "All Inverters"
        case .inverter(let id): model.inverters.first { $0.id == id }?.name ?? "Inverter"
        }
    }

    private var selectionStatus: InverterStatus? {
        guard case .inverter(let id) = model.selection else { return nil }
        return model.inverters.first { $0.id == id }?.status
    }

    /// The inverter whose intraday chart we show. For "All" we use the first one
    /// (the intraday endpoint is per-inverter).
    private var focusInverterID: Int? {
        model.selection.inverterID ?? model.inverters.first?.id
    }

    private var emptyState: some View {
        Card {
            VStack(spacing: 8) {
                Image(systemName: "sun.max").font(.largeTitle).foregroundStyle(GhrianColor.inverter)
                Text(model.isLoading ? "Loading…" : "No inverters yet")
                    .foregroundStyle(GhrianColor.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }
}

/// The live power-flow + battery overview for the current selection.
struct LiveOverviewCard: View {
    let combined: CombinedSnapshot
    let title: String
    var status: InverterStatus?

    var body: some View {
        Card {
            HStack {
                Text(title).font(.headline).foregroundStyle(GhrianColor.textPrimary)
                Spacer()
                if let status { StatusBadge(status: status) }
            }
            PowerFlowDiagram(flows: combined.flows)
                .frame(maxWidth: 360)
                .frame(maxWidth: .infinity)
            if combined.batterySoc != nil {
                HStack(spacing: 16) {
                    BatteryRing(soc: combined.batterySoc)
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(combined.flows) { flow in
                            HStack {
                                Circle().fill(GhrianColor.flow(flow.key)).frame(width: 8, height: 8)
                                Text(flow.label).foregroundStyle(GhrianColor.textSecondary)
                                Spacer()
                                Text(GhrianFormat.kw(flow.kw)).foregroundStyle(GhrianColor.textPrimary).monospacedDigit()
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
    }
}
