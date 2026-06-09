import Foundation

/// Shared, surface-spanning persistence: the server URL + tracked-inverter selection
/// live in App-Group `UserDefaults`; the API token lives in the Keychain (optionally a
/// shared access group) so the app, widget, and menu-bar all read the same credentials.
///
/// `appGroup` / `keychainAccessGroup` are deployment-specific — set them to match the
/// app's entitlements. With `appGroup == nil` it falls back to standard defaults
/// (fine for a single target / previews / tests).
public final class GhrianStore: @unchecked Sendable {
    public struct Config: Sendable {
        public var appGroup: String?
        public var keychainService: String
        public var keychainAccessGroup: String?

        public init(appGroup: String? = nil,
                    keychainService: String = "me.zavan.ghrian.apitoken",
                    keychainAccessGroup: String? = nil) {
            self.appGroup = appGroup
            self.keychainService = keychainService
            self.keychainAccessGroup = keychainAccessGroup
        }
    }

    private enum Keys {
        static let serverURL = "ghrian.serverURL"
        static let selection = "ghrian.selection"
        static let pollInterval = "ghrian.pollInterval"
    }

    private let config: Config
    let defaults: UserDefaults

    public init(config: Config = Config()) {
        self.config = config
        self.defaults = config.appGroup.flatMap { UserDefaults(suiteName: $0) } ?? .standard
    }

    // MARK: Server URL

    public var serverURL: URL? {
        get { defaults.string(forKey: Keys.serverURL).flatMap(URL.init(string:)) }
        set { defaults.set(newValue?.absoluteString, forKey: Keys.serverURL) }
    }

    // MARK: API token (Keychain)

    public var token: String? {
        get { Keychain.read(service: config.keychainService, accessGroup: config.keychainAccessGroup) }
        set {
            if let newValue, !newValue.isEmpty {
                Keychain.write(newValue, service: config.keychainService, accessGroup: config.keychainAccessGroup)
            } else {
                Keychain.delete(service: config.keychainService, accessGroup: config.keychainAccessGroup)
            }
        }
    }

    // MARK: Selection

    public var selection: InverterSelection {
        get {
            defaults.string(forKey: Keys.selection).flatMap(InverterSelection.init(storageValue:)) ?? .all
        }
        set { defaults.set(newValue.storageValue, forKey: Keys.selection) }
    }

    // MARK: Poll interval (seconds)

    public var pollInterval: TimeInterval {
        get {
            let stored = defaults.double(forKey: Keys.pollInterval)
            return stored > 0 ? stored : 30
        }
        set { defaults.set(newValue, forKey: Keys.pollInterval) }
    }

    // MARK: Convenience

    public var isConfigured: Bool { serverURL != nil && (token?.isEmpty == false) }

    /// A ready-to-use client, or nil if the URL/token aren't set yet.
    public func makeClient(session: URLSession = .shared) -> GhrianClient? {
        guard let serverURL, let token, !token.isEmpty else { return nil }
        return GhrianClient(baseURL: serverURL, token: token, session: session)
    }

    public func clear() {
        serverURL = nil
        token = nil
        defaults.removeObject(forKey: Keys.selection)
    }
}
