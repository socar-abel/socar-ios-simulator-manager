import SwiftUI
import Core
import Domain
import Data
import Feature

@main
struct SOCARSimulatorManagerApp: App {

    @State private var coordinator: AppCoordinator

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
        let assembly = AppAssembly()
        _coordinator = State(initialValue: AppCoordinator(assembly: assembly))
    }

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
                .onAppear {
                    NSApplication.shared.activate(ignoringOtherApps: true)
                }
        }
        .defaultSize(width: 1100, height: 700)

        Settings {
            if let vm = coordinator.settingsViewModel {
                SettingsView(viewModel: vm)
            }
        }
    }
}
