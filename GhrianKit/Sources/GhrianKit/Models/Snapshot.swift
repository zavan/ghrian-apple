import Foundation

/// Display-ready overview computed server-side by `Inverter::Snapshot`.
public struct InverterSnapshot: Codable, Sendable {
    public let flows: Flows
    public let batterySoc: Double?
    public let temperature: Double?
    public let today: TodayEnergy

    enum CodingKeys: String, CodingKey {
        case flows, temperature, today
        case batterySoc = "battery_soc"
    }
}

/// The four power-flow nodes. Watts are signed per the API's conventions; `direction`
/// is relative to the inverter hub (`.incoming` = into the inverter).
public struct Flows: Codable, Sendable {
    public let pv: Flow
    public let grid: Flow
    public let battery: Flow
    public let load: Flow

    public var all: [Flow] { [pv, grid, battery, load] }
}

public struct Flow: Codable, Sendable, Identifiable {
    public let key: String
    public let label: String
    public let watts: Double?
    public let kw: Double?
    public let direction: FlowDirection

    public var id: String { key }
    public var isActive: Bool { direction != .idle && (watts ?? 0) != 0 }

    public init(key: String, label: String, watts: Double?, kw: Double?, direction: FlowDirection) {
        self.key = key
        self.label = label
        self.watts = watts
        self.kw = kw
        self.direction = direction
    }
}

public enum FlowDirection: String, Codable, Sendable {
    case incoming = "in"
    case outgoing = "out"
    case idle
}

/// Today's cumulative energy (kWh), reset by the device at midnight. `generation`
/// is the API's `yield` field (renamed to avoid the `yield` contextual keyword and
/// to match the energy endpoint's naming).
public struct TodayEnergy: Codable, Sendable {
    public let generation: Double?
    public let charge: Double?
    public let discharge: Double?
    public let toGrid: Double?
    public let fromGrid: Double?
    public let consumption: Double?

    enum CodingKeys: String, CodingKey {
        case generation = "yield"
        case charge, discharge, consumption
        case toGrid = "to_grid"
        case fromGrid = "from_grid"
    }

    public init(
        generation: Double?, charge: Double?, discharge: Double?,
        toGrid: Double?, fromGrid: Double?, consumption: Double?
    ) {
        self.generation = generation
        self.charge = charge
        self.discharge = discharge
        self.toGrid = toGrid
        self.fromGrid = fromGrid
        self.consumption = consumption
    }
}
