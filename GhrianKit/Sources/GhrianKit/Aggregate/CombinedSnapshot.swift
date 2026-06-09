import Foundation

/// A site-wide "All inverters" overview: power flows summed across inverters (with
/// directions recomputed from the signed totals), SOC averaged, today's energy
/// summed. Lets the switchable widget/menu-bar treat "All" like a single inverter.
public struct CombinedSnapshot: Sendable {
    public let pv: Flow
    public let grid: Flow
    public let battery: Flow
    public let load: Flow
    public let batterySoc: Double?
    public let today: TodayEnergy

    public var flows: [Flow] { [pv, grid, battery, load] }

    public init(inverters: [Inverter]) {
        let snapshots = inverters.map(\.snapshot)

        // PV always flows into the hub; Load always out.
        let pvWatts = snapshots.compactMap { $0.flows.pv.watts }.reduce(0, +)
        let loadWatts = snapshots.compactMap { $0.flows.load.watts }.reduce(0, +)

        // Grid is already signed (+ export / − import) in each snapshot.
        let gridWatts = snapshots.compactMap { $0.flows.grid.watts }.reduce(0, +)

        // Battery watts are magnitudes; sign by direction (out = charging) before summing.
        let batteryWatts = snapshots.reduce(0.0) { sum, snapshot in
            let flow = snapshot.flows.battery
            guard let watts = flow.watts else { return sum }
            switch flow.direction {
            case .outgoing: return sum + watts   // charging
            case .incoming: return sum - watts   // discharging
            case .idle: return sum
            }
        }

        pv = CombinedSnapshot.flow(key: "pv", label: "PV", signed: pvWatts, alwaysInto: true)
        load = CombinedSnapshot.flow(key: "load", label: "Load", signed: loadWatts, alwaysOut: true)
        grid = CombinedSnapshot.flow(key: "grid", label: "Grid", signed: gridWatts)
        battery = CombinedSnapshot.flow(key: "battery", label: "Battery", signed: batteryWatts)

        let socs = snapshots.compactMap(\.batterySoc)
        batterySoc = socs.isEmpty ? nil : socs.reduce(0, +) / Double(socs.count)

        today = TodayEnergy(
            generation: CombinedSnapshot.sum(snapshots) { $0.today.generation },
            charge: CombinedSnapshot.sum(snapshots) { $0.today.charge },
            discharge: CombinedSnapshot.sum(snapshots) { $0.today.discharge },
            toGrid: CombinedSnapshot.sum(snapshots) { $0.today.toGrid },
            fromGrid: CombinedSnapshot.sum(snapshots) { $0.today.fromGrid },
            consumption: CombinedSnapshot.sum(snapshots) { $0.today.consumption }
        )
    }

    private static func flow(
        key: String, label: String, signed: Double,
        alwaysInto: Bool = false, alwaysOut: Bool = false
    ) -> Flow {
        let direction: FlowDirection
        if alwaysInto {
            direction = signed == 0 ? .idle : .incoming
        } else if alwaysOut {
            direction = signed == 0 ? .idle : .outgoing
        } else if signed > 0 {
            direction = .outgoing
        } else if signed < 0 {
            direction = .incoming
        } else {
            direction = .idle
        }
        return Flow(key: key, label: label, watts: abs(signed), kw: abs(signed) / 1000, direction: direction)
    }

    private static func sum(_ snapshots: [InverterSnapshot], _ value: (InverterSnapshot) -> Double?) -> Double? {
        let present = snapshots.compactMap(value)
        return present.isEmpty ? nil : present.reduce(0, +)
    }
}
