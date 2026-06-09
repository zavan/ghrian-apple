import Foundation
import Observation
import GhrianKit

/// Observable app state: holds credentials/store, the polled inverter list, and the
/// current selection. Lives on the main actor; polling and fetches hop to the client.
@MainActor
@Observable
final class AppModel {
    let store: GhrianStore

    var inverters: [Inverter] = []
    var isLoading = false
    var errorMessage: String?
    private(set) var lastUpdated: Date?

    /// Observable mirror of "are credentials set" — drives routing/polling, since
    /// the underlying store (UserDefaults/Keychain) isn't itself observable.
    var isConnected: Bool

    private var pollTask: Task<Void, Never>?

    init(store: GhrianStore) {
        self.store = store
        self.isConnected = store.isConfigured
    }

    var selection: InverterSelection {
        get { store.selection }
        set { store.selection = newValue }
    }

    /// The inverters matching the current selection (all for `.all`).
    var selectedInverters: [Inverter] {
        switch selection {
        case .all: inverters
        case .inverter(let id): inverters.filter { $0.id == id }
        }
    }

    /// Combined flows for the selection — a single inverter or the site-wide aggregate.
    var combined: CombinedSnapshot {
        CombinedSnapshot(inverters: selectedInverters)
    }

    var currencyHint: String { "$" }

    // MARK: Loading

    @discardableResult
    func load() async -> Bool {
        guard let client = store.makeClient() else { return false }
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await client.inverters()
            inverters = fetched
            store.cacheInverterList(fetched)
            lastUpdated = Date()
            errorMessage = nil
            return true
        } catch {
            errorMessage = message(for: error)
            return false
        }
    }

    func intraday(inverterID: Int, date: Date) async -> IntradaySeries? {
        guard let client = store.makeClient() else { return nil }
        return try? await client.intraday(inverterID: inverterID, date: date)
    }

    func energy(inverterID: Int?, period: EnergyPeriod, date: Date) async -> EnergyReport? {
        guard let client = store.makeClient() else { return nil }
        do {
            return try await client.energy(inverterID: inverterID, period: period, date: date)
        } catch {
            errorMessage = message(for: error)
            return nil
        }
    }

    // MARK: Polling

    func startPolling() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let seconds = await self.tick()
                try? await Task.sleep(for: .seconds(seconds))
            }
        }
    }

    private func tick() async -> TimeInterval {
        await load()
        return store.pollInterval
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: Credentials

    /// Validate + store the server URL and token, then attempt a load. Returns an
    /// error message on failure, nil on success.
    func connect(urlString: String, token: String) async -> String? {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: trimmed), url.scheme != nil, url.host != nil else {
            return "Enter a valid server URL (e.g. http://192.168.1.10:3000)."
        }
        let cleanToken = token.trimmingCharacters(in: .whitespaces)
        guard !cleanToken.isEmpty else { return "Enter an API token." }

        store.serverURL = url
        store.token = cleanToken
        isConnected = true

        if await load() { return nil }
        return errorMessage ?? "Couldn't connect."
    }

    func signOut() {
        stopPolling()
        store.clear()
        inverters = []
        lastUpdated = nil
        errorMessage = nil
        isConnected = false
    }

    private func message(for error: Error) -> String {
        (error as? APIError)?.errorDescription ?? error.localizedDescription
    }
}
