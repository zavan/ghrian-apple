import SwiftUI
import GhrianKit

/// Top-level entry: hosts the navigation shell and owns the polling lifecycle. Appearance
/// follows the system (no forced dark) so the content layer adapts and the Liquid Glass
/// control layer reads correctly in light and dark.
struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        AppShell()
            .onChange(of: model.isConnected, initial: true) { _, connected in
                if connected { model.startPolling() } else { model.stopPolling() }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active, model.isConnected {
                    Task { await model.load() }
                }
            }
    }
}
