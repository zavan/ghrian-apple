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

    /// A compact "updated N ago" relative label for the live footer. `now` is injectable
    /// for testing. "just now" under 5s, then "12s ago", "5m ago", "2h ago", "3d ago".
    public static func relativeUpdated(_ date: Date?, now: Date = Date()) -> String {
        guard let date else { return "Never updated" }
        let seconds = max(0, now.timeIntervalSince(date))
        let phrase: String
        switch seconds {
        case ..<5: phrase = "just now"
        case ..<60: phrase = "\(Int(seconds))s ago"
        case ..<3600: phrase = "\(Int(seconds / 60))m ago"
        case ..<86_400: phrase = "\(Int(seconds / 3600))h ago"
        default: phrase = "\(Int(seconds / 86_400))d ago"
        }
        return "Updated \(phrase)"
    }

    /// The Overview hero headline derived from the (signed) grid flow: whether the site is
    /// pulling from or pushing to the grid, plus the magnitude. `.outgoing` = exporting,
    /// `.incoming` = importing (directions are relative to the inverter hub).
    public static func gridHeadline(_ grid: Flow?) -> GridHeadline {
        guard let grid, grid.isActive else {
            return GridHeadline(title: "Grid idle", value: kw(grid?.kw))
        }
        switch grid.direction {
        case .outgoing: return GridHeadline(title: "Exporting", value: kw(grid.kw))
        case .incoming: return GridHeadline(title: "Importing", value: kw(grid.kw))
        case .idle: return GridHeadline(title: "Grid idle", value: kw(grid.kw))
        }
    }

    private static func round3(_ value: Double) -> String {
        let rounded = (value * 1000).rounded() / 1000
        return rounded == rounded.rounded() ? String(Int(rounded)) : String(rounded)
    }
}

/// A two-line headline (title + value) for the Overview hero.
public struct GridHeadline: Equatable, Sendable {
    public let title: String
    public let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }
}
