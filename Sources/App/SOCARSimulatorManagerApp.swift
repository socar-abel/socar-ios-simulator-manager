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
        Self.setAppIcon()
        let assembly = AppAssembly()
        _coordinator = State(initialValue: AppCoordinator(assembly: assembly))
    }

    private static func setAppIcon() {
        let config = NSImage.SymbolConfiguration(pointSize: 128, weight: .medium)
            .applying(.init(paletteColors: [.systemBlue, .systemCyan]))
        if let image = NSImage(systemSymbolName: "iphone.radiowaves.left.and.right", accessibilityDescription: "SOCAR Simulator Manager") {
            let configured = image.withSymbolConfiguration(config) ?? image
            NSApplication.shared.applicationIconImage = configured
        }
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
