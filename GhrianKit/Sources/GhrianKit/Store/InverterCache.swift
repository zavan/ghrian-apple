import Foundation

/// A lightweight inverter identity persisted to the App Group so the widget's
/// configuration picker can list inverters without a network call.
public struct CachedInverter: Codable, Sendable, Identifiable, Equatable {
    public let id: Int
    public let name: String

    public init(id: Int, name: String) {
        self.id = id
        self.name = name
    }

    public init(_ inverter: Inverter) {
        self.id = inverter.id
        self.name = inverter.name
    }
}

public extension GhrianStore {
    private static let cachedInvertersKey = "ghrian.cachedInverters"

    /// Mirror the inverter list into the App Group (called by the app after a load).
    func cacheInverterList(_ inverters: [Inverter]) {
        let cached = inverters.map(CachedInverter.init)
        guard let data = try? JSONEncoder().encode(cached) else { return }
        defaults.set(data, forKey: Self.cachedInvertersKey)
    }

    /// The last-known inverter list (for the widget config picker / offline).
    func cachedInverterList() -> [CachedInverter] {
        guard let data = defaults.data(forKey: Self.cachedInvertersKey),
              let cached = try? JSONDecoder().decode([CachedInverter].self, from: data) else { return [] }
        return cached
    }
}
