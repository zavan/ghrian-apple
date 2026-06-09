import SwiftUI
import GhrianKit

struct RootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            GhrianColor.background.ignoresSafeArea()
            if model.isConnected {
                DashboardView()
            } else {
                NavigationStack {
                    SettingsView(isOnboarding: true)
                }
            }
        }
        .preferredColorScheme(.dark)
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
