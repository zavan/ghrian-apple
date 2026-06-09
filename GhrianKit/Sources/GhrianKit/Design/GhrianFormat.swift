import Foundation

/// Display formatting matching the web frontend (`Inverter::Snapshot` / `Tariff`).
public enum GhrianFormat {
    /// "1.194 kW" / "—" — from signed watts (magnitude shown).
    public static func kw(watts: Double?) -> String {
        guard let watts else { return "—" }
        return "\(round3(abs(watts) / 1000)) kW"
    }

    /// "1.194 kW" / "—" — from a pre-divided kW value (e.g. `Flow.kw`).
    public static func kw(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(round3(abs(value))) kW"
    }

    /// "12.34 kWh" / "—"
    public static func kwh(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.2f kWh", value)
    }

    /// "85%" / "—"
    public static func percent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(Int(value.rounded()))%"
    }

    /// "24.5°C" / "—"
    public static func temperature(_ value: Double?) -> String {
        guard let value else { return "—" }
        return String(format: "%.1f°C", value)
    }

    /// "$12.34" / "-$1.20"
    public static func money(_ amount: Double, currency: String) -> String {
        let sign = amount < 0 ? "-" : ""
        return "\(sign)\(currency)\(String(format: "%.2f", abs(amount)))"
    }

    private static func round3(_ value: Double) -> String {
        let rounded = (value * 1000).rounded() / 1000
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(rounded)
    }
}
