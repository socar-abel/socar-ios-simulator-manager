import SwiftUI
import Routing
import EnvironmentDomain
import DeviceFeature
import BuildFeature
import SettingsFeature
import RuntimeFeature

enum AppRoute: Hashable {
    case devices
    case builds
    case runtimes
}

@Observable
@MainActor
final class AppCoordinator {

    var childCoordinators: [any Coordinator] = []

    var selectedTab: AppRoute = .devices
    var environmentStatus: EnvironmentStatus?
    var isCheckingEnvironment = true
    var isReady = false

    private(set) var deviceListViewModel: DeviceListViewModel?
    private(set) var buildListViewModel: BuildListViewModel?
    private(set) var settingsViewModel: SettingsViewModel?
    private(set) var runtimeViewModel: RuntimeViewModel?

    private let assembly: AppAssembly

    init(assembly: AppAssembly) {
        self.assembly = assembly
    }

    func start() async {
        isCheckingEnvironment = true
        environmentStatus = await assembly.environmentCheckUseCase().check()
        isCheckingEnvironment = false

        guard environmentStatus?.isReady == true else { return }

        do {
            deviceListViewModel = try await assembly.deviceListViewModel()
            buildListViewModel = try await assembly.buildListViewModel()
            settingsViewModel = assembly.settingsViewModel()
            runtimeViewModel = try await assembly.runtimeViewModel()
            isReady = true
        } catch {
            environmentStatus = EnvironmentStatus(
                xcodeInstalled: false,
                xcodePath: nil,
                xcodeVersion: nil,
                commandLineToolsInstalled: false,
                availableRuntimes: []
            )
        }
    }

    func retryEnvironmentCheck() async {
        await start()
    }
}
