import Foundation

/// Last-known daily values for a widget selection, cached in the App Group so the
/// widget can render something when a timeline refresh can't reach the server.
public struct WidgetSnapshot: Codable, Sendable {
    public let title: String
    public let today: TodayEnergy?
    public let soc: Double?
    public let date: Date

    public init(title: String, today: TodayEnergy?, soc: Double?, date: Date) {
        self.title = title
        self.today = today
        self.soc = soc
        self.date = date
    }
}

public extension GhrianStore {
    private static func widgetKey(_ selection: InverterSelection) -> String {
        "ghrian.widgetSnapshot.\(selection.storageValue)"
    }

    func cacheWidgetSnapshot(_ snapshot: WidgetSnapshot, for selection: InverterSelection) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.widgetKey(selection))
    }

    func cachedWidgetSnapshot(for selection: InverterSelection) -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: Self.widgetKey(selection)) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
