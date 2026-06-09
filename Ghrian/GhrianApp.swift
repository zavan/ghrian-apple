import SwiftUI
import GhrianKit

@main
struct GhrianApp: App {
    @State private var model = AppModel(store: AppConfig.makeStore())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .tint(GhrianColor.grid)
                #if os(macOS)
                .frame(minWidth: 420, minHeight: 640)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 480, height: 880)
        .windowResizability(.contentMinSize)
        #endif

        #if os(macOS)
        MenuBarExtra {
            MenuBarView()
                .environment(model)
                .frame(width: 360, height: 520)
        } label: {
            MenuBarLabel(model: model)
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}
