import SwiftUI
import SettingsFeature

@main
struct SOCARSimulatorManagerApp: App {

    @State private var coordinator: AppCoordinator

    init() {
        let assembly = AppAssembly()
        _coordinator = State(initialValue: AppCoordinator(assembly: assembly))
    }

    var body: some Scene {
        WindowGroup {
            RootView(coordinator: coordinator)
        }
        .windowResizability(.contentSize)

        Settings {
            if let vm = coordinator.settingsViewModel {
                SettingsView(viewModel: vm)
            }
        }
    }
}
