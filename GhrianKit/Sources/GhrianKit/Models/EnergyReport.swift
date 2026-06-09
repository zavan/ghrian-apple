import Foundation

public enum EnergyPeriod: String, Codable, Sendable, CaseIterable, Identifiable {
    case day, month, year, lifetime
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .day: "Day"
        case .month: "Month"
        case .year: "Year"
        case .lifetime: "Lifetime"
        }
    }
}

/// `GET /api/v1/inverters/:id/energy` (per-inverter) or `GET /api/v1/energy`
/// (site-wide). Period totals in kWh plus costs in the tariff currency.
public struct EnergyReport: Codable, Sendable {
    public let inverterId: Int?
    public let period: EnergyPeriod
    public let date: String
    public let label: String
    public let range: Range
    public let currency: String
    public let tariffConfigured: Bool
    public let totals: Totals
    public let costs: Costs
    public let breakdownUnit: String?
    public let breakdown: [BreakdownPoint]?

    public struct Range: Codable, Sendable {
        public let from: String
        public let to: String
    }

    public struct Totals: Codable, Sendable {
        public let generation: Double
        public let selfConsumption: Double
        public let feedIn: Double
        public let `import`: Double
        public let consumption: Double
        public let charge: Double
        public let discharge: Double

        enum CodingKeys: String, CodingKey {
            case generation, consumption, charge, discharge
            case selfConsumption = "self_consumption"
            case feedIn = "feed_in"
            case `import`
        }
    }

    public struct Costs: Codable, Sendable {
        public let importCost: Double
        public let exportEarnings: Double
        public let net: Double
        public let savings: Double

        enum CodingKeys: String, CodingKey {
            case net, savings
            case importCost = "import_cost"
            case exportEarnings = "export_earnings"
        }
    }

    public struct BreakdownPoint: Codable, Sendable, Identifiable {
        public let label: String
        public let value: Double
        public var id: String { label }
    }

    enum CodingKeys: String, CodingKey {
        case period, date, label, range, currency, totals, costs, breakdown
        case inverterId = "inverter_id"
        case tariffConfigured = "tariff_configured"
        case breakdownUnit = "breakdown_unit"
    }
}
