import SwiftUI
import Core
import Domain
import Data
import Feature

@main
struct SOCARSimulatorManagerApp: App {

    @State private var coordinator: AppContainer

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        let assembly = AppAssembly()
        _coordinator = State(initialValue: AppContainer(assembly: assembly))
    }

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 1100, height: 900)

        Settings {
            if let vm = coordinator.settingsViewModel {
                SettingsView(viewModel: vm)
            }
        }
    }
}
