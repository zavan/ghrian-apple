import AppIntents
import GhrianKit

/// A selectable inverter for the widget's configuration. Options come from the
/// App-Group-cached inverter list the app writes on each load (no network here).
/// `id < 0` represents the site-wide "All" aggregate.
struct InverterEntity: AppEntity {
    let id: Int
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation { "Inverter" }
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
    static let defaultQuery = InverterEntityQuery()

    static let all = InverterEntity(id: -1, name: "All Inverters")
}

struct InverterEntityQuery: EntityQuery {
    func entities(for identifiers: [Int]) async throws -> [InverterEntity] {
        options().filter { identifiers.contains($0.id) }
    }

    func suggestedEntities() async throws -> [InverterEntity] {
        options()
    }

    func defaultResult() -> InverterEntity? { .all }

    private func options() -> [InverterEntity] {
        let cached = AppConfig.makeStore().cachedInverterList()
            .map { InverterEntity(id: $0.id, name: $0.name) }
        return [.all] + cached
    }
}

struct SelectInverterIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Select Inverter" }
    static var description: IntentDescription { "Choose which inverter the widget shows." }

    @Parameter(title: "Inverter")
    var inverter: InverterEntity?
}
