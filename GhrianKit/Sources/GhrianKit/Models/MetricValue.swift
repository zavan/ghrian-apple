import Foundation

/// One entry of an inverter's raw `latest_values` map: a self-describing
/// `{ value, unit, label }` where `value` may be a number, string, bool, or list
/// of strings (bitfields). Decoded defensively — unknown shapes become `.null`.
public struct MetricValue: Codable, Sendable {
    public let value: JSONValue
    public let unit: String?
    public let label: String?

    public var doubleValue: Double? { value.doubleValue }

    /// Human-friendly rendering of value + unit, e.g. "3500 W" or "online".
    public var display: String {
        let base = value.display
        guard let unit, !unit.isEmpty else { return base }
        return "\(base) \(unit)"
    }
}

public enum JSONValue: Codable, Sendable, Equatable {
    case number(Double)
    case bool(Bool)
    case string(String)
    case list([String])
    case null

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self = .null
        } else if let n = try? c.decode(Double.self) {
            self = .number(n)
        } else if let b = try? c.decode(Bool.self) {
            self = .bool(b)
        } else if let s = try? c.decode(String.self) {
            self = .string(s)
        } else if let a = try? c.decode([String].self) {
            self = .list(a)
        } else {
            self = .null
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .number(let n): try c.encode(n)
        case .bool(let b): try c.encode(b)
        case .string(let s): try c.encode(s)
        case .list(let a): try c.encode(a)
        case .null: try c.encodeNil()
        }
    }

    public var doubleValue: Double? {
        if case .number(let n) = self { return n }
        return nil
    }

    public var display: String {
        switch self {
        case .number(let n): return n == n.rounded() ? String(Int(n)) : String(n)
        case .bool(let b): return b ? "true" : "false"
        case .string(let s): return s
        case .list(let a): return a.joined(separator: ", ")
        case .null: return "—"
        }
    }
}
