import SwiftUI
import RoutingKit
import EnvironmentDomain
import DeviceFeature
import BuildFeature
import SettingsFeature

enum AppRoute: Hashable {
    case devices
    case builds
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

    private let assembly: AppAssembly

    init(assembly: AppAssembly) {
        self.assembly = assembly
    }

    func start() async {
        // 1. 환경 확인
        isCheckingEnvironment = true
        environmentStatus = await assembly.environmentCheckUseCase().check()
        isCheckingEnvironment = false

        guard environmentStatus?.isReady == true else { return }

        // 2. ViewModel 조립
        do {
            deviceListViewModel = try await assembly.deviceListViewModel()
            buildListViewModel = try await assembly.buildListViewModel()
            settingsViewModel = assembly.settingsViewModel()
            isReady = true
        } catch {
            // Shell 초기화 실패 등
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
