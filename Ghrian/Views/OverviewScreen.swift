import SwiftUI
import GhrianKit

/// The live home screen: a power-flow hero (current grid headline, animated flow diagram,
/// battery) on the flat content layer, plus today's energy. Polls via `AppModel`; pull to
/// refresh on iOS, an explicit button on macOS.
struct OverviewScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if model.inverters.isEmpty {
                    emptyState
                } else {
                    HeroSection(combined: model.combined,
                                title: selectionTitle,
                                status: selectionStatus)
                    TodayEnergyGrid(today: model.combined.today)
                    footer
                }

                if let error = model.errorMessage {
                    Text(error).font(.callout).foregroundStyle(GhrianColor.offline)
                }
            }
            .padding()
            .frame(maxWidth: 720)
            .frame(maxWidth: .infinity)
        }
        .background(GhrianColor.background)
        .navigationTitle("Overview")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .inverterToolbar()
        .refreshable { await model.load() }
        .task { await model.load() }
    }

    private var footer: some View {
        HStack(spacing: 6) {
            if selectionStatus == .online || selectionStatus == nil {
                PulsingDot(color: GhrianColor.online)
            }
            Text(GhrianFormat.relativeUpdated(model.lastUpdated))
                .font(.caption)
                .foregroundStyle(GhrianColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(model.isLoading ? "Loading…" : "No inverters yet", systemImage: "sun.max")
        } description: {
            Text(model.isLoading ? "Fetching your inverters." : "Add an inverter in the ghrian web admin.")
        }
        .padding(.top, 40)
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
}

/// The power-flow hero. Charts/diagram stay on the content layer; only the status badge
/// floats in glass.
struct HeroSection: View {
    let combined: CombinedSnapshot
    let title: String
    var status: InverterStatus?

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.title3.weight(.semibold)).foregroundStyle(GhrianColor.textPrimary)
                Spacer()
                if let status { StatusBadge(status: status) }
            }

            headline

            PowerFlowDiagram(flows: combined.flows)
                .frame(maxWidth: 380)
                .frame(maxWidth: .infinity)

            if combined.batterySoc != nil {
                HStack(spacing: 16) {
                    BatteryRing(soc: combined.batterySoc)
                    legend
                }
            }
        }
    }

    private var headline: some View {
        let h = GhrianFormat.gridHeadline(combined.grid)
        return VStack(spacing: 2) {
            Text(h.value)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(GhrianColor.textPrimary)
            Text(h.title)
                .font(.subheadline)
                .foregroundStyle(GhrianColor.textSecondary)
        }
        .animation(.snappy, value: combined.grid.watts)
        .animation(.snappy, value: combined.grid.direction)
    }

    private var legend: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(combined.flows) { flow in
                HStack {
                    Circle().fill(GhrianColor.flow(flow.key)).frame(width: 8, height: 8)
                    Text(flow.label).foregroundStyle(GhrianColor.textSecondary)
                    Spacer()
                    Text(GhrianFormat.kw(flow.kw))
                        .foregroundStyle(GhrianColor.textPrimary)
                        .monospacedDigit()
                        .contentTransition(.numericText())
                }
                .font(.caption)
                .animation(.snappy, value: flow.watts)
            }
        }
    }
}
