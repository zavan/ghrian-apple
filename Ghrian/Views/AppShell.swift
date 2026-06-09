import SwiftUI
import GhrianKit

/// The size-class-adaptive navigation shell.
///
/// - **Compact (iPhone)** → a `TabView` (Overview · Energy · Settings). On the 26 OSes the
///   tab bar is the floating Liquid Glass bar; it minimizes on scroll and carries a live
///   power readout in its bottom accessory.
/// - **Regular (iPad / Mac)** → a `NavigationSplitView` whose glass sidebar lists the
///   inverters (All + each) plus Energy and Settings.
///
/// Not connected → full-window onboarding (no chrome).
struct AppShell: View {
    @Environment(AppModel.self) private var model
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif

    var body: some View {
        if model.isConnected {
            #if os(iOS)
            if sizeClass == .compact { tabs } else { split }
            #else
            split
            #endif
        } else {
            NavigationStack { SettingsScreen(isOnboarding: true) }
        }
    }

    // MARK: Compact — tabs

    private var tabs: some View {
        TabView {
            Tab("Overview", systemImage: "bolt.fill") {
                NavigationStack { OverviewScreen() }
            }
            Tab("Energy", systemImage: "chart.bar.fill") {
                NavigationStack { EnergyScreen() }
            }
            Tab("Settings", systemImage: "gearshape") {
                NavigationStack { SettingsScreen() }
            }
        }
        #if os(iOS)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory { LivePowerAccessory() }
        #endif
    }

    // MARK: Regular — sidebar + detail

    @State private var sidebarSelection: SidebarItem? = .inverter(.all)

    private var split: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .onAppear { sidebarSelection = .inverter(model.selection) }
        .onChange(of: sidebarSelection) { _, item in
            if case .inverter(let selection)? = item { model.selection = selection }
        }
        .task { await model.load() }
    }

    private var sidebar: some View {
        List(selection: $sidebarSelection) {
            Section("Inverters") {
                Label("All Inverters", systemImage: "square.grid.2x2.fill")
                    .tag(SidebarItem.inverter(.all))
                ForEach(model.inverters) { inverter in
                    InverterSidebarRow(inverter: inverter)
                        .tag(SidebarItem.inverter(.inverter(inverter.id)))
                }
            }
            Section {
                Label("Energy", systemImage: "chart.bar.fill").tag(SidebarItem.energy)
                Label("Settings", systemImage: "gearshape").tag(SidebarItem.settings)
            }
        }
        .navigationTitle("ghrian")
        #if os(macOS)
        .toolbar { ToolbarItem { RefreshButton() } }
        #endif
    }

    @ViewBuilder private var detail: some View {
        switch sidebarSelection {
        case .energy: EnergyScreen()
        case .settings: SettingsScreen()
        default: OverviewScreen()
        }
    }
}

/// What the regular-width sidebar selects: an inverter (or All) to view, or a standalone screen.
enum SidebarItem: Hashable {
    case inverter(InverterSelection)
    case energy
    case settings
}

/// A sidebar row for one inverter: name, a live status dot, and current PV output.
struct InverterSidebarRow: View {
    let inverter: Inverter

    var body: some View {
        Label {
            HStack {
                Text(inverter.name)
                Spacer()
                Text(GhrianFormat.kw(inverter.snapshot.flows.pv.kw))
                    .font(.caption).monospacedDigit()
                    .foregroundStyle(GhrianColor.textSecondary)
            }
        } icon: {
            Circle().fill(GhrianColor.status(inverter.status)).frame(width: 8, height: 8)
        }
    }
}

/// The shared inverter switcher + (on macOS) refresh, attached to the Overview/Energy nav bars.
struct InverterToolbar: ViewModifier {
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .primaryAction) { InverterPicker() }
            #if os(macOS)
            ToolbarItem(placement: .primaryAction) { RefreshButton() }
            #endif
        }
    }
}

extension View {
    func inverterToolbar() -> some View { modifier(InverterToolbar()) }
}

/// A compact menu picker over the inverters (incl. "All"). Hidden when there's only one.
struct InverterPicker: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        if model.inverters.count > 1 {
            Picker("Inverter", selection: $model.selection) {
                Label("All", systemImage: "square.grid.2x2").tag(InverterSelection.all)
                ForEach(model.inverters) { inverter in
                    Text(inverter.name).tag(InverterSelection.inverter(inverter.id))
                }
            }
            .pickerStyle(.menu)
        }
    }
}

struct RefreshButton: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Button { Task { await model.load() } } label: {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(model.isLoading)
    }
}

#if os(iOS)
/// The live current-power chip shown in the tab bar's glass bottom accessory.
struct LivePowerAccessory: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let headline = GhrianFormat.gridHeadline(model.combined.grid)
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill").foregroundStyle(GhrianColor.inverter)
            Text(headline.title).foregroundStyle(GhrianColor.textSecondary)
            Spacer()
            Text(headline.value)
                .fontWeight(.semibold).monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: model.combined.grid.watts)
        }
        .font(.subheadline)
        .lineLimit(1)
        .padding(.horizontal, 14)
    }
}
#endif
