import Foundation

/// Which inverter a surface (widget / menu-bar) is tracking. `.all` is the
/// site-wide aggregate (see `CombinedSnapshot`).
public enum InverterSelection: Codable, Sendable, Equatable, Hashable {
    case all
    case inverter(Int)

    /// Compact persisted form: "all" or "inv:<id>".
    public var storageValue: String {
        switch self {
        case .all: "all"
        case .inverter(let id): "inv:\(id)"
        }
    }

    public init?(storageValue: String) {
        if storageValue == "all" {
            self = .all
        } else if storageValue.hasPrefix("inv:"), let id = Int(storageValue.dropFirst(4)) {
            self = .inverter(id)
        } else {
            return nil
        }
    }

    /// The matching inverter id, or nil for `.all` (site-wide).
    public var inverterID: Int? {
        if case .inverter(let id) = self { return id }
        return nil
    }
}
