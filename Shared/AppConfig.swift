import Foundation
import GhrianKit

/// Deployment-specific identifiers shared by the app, widget, and menu-bar. The
/// App Group shares the server URL + selection + cached inverter list; the API
/// token lives in the Keychain. `keychainAccessGroup` is left nil so items land in
/// the first `keychain-access-groups` entitlement (the shared group), which both
/// targets declare — so they share the token once signed with a team.
enum AppConfig {
    static let appGroup = "group.me.zavan.ghrian"
    static let keychainService = "me.zavan.ghrian.apitoken"

    static var storeConfig: GhrianStore.Config {
        GhrianStore.Config(
            appGroup: appGroup,
            keychainService: keychainService,
            keychainAccessGroup: nil
        )
    }

    static func makeStore() -> GhrianStore {
        GhrianStore(config: storeConfig)
    }
}
