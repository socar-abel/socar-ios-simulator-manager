import SwiftUI
import Core
import Domain
import Data
import Feature

enum AppRoute: Hashable {
    case devices
    case builds
    case iosVersions
    case guide
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
    private(set) var iosVersionViewModel: IOSVersionViewModel?

    private let assembly: AppAssembly

    init(assembly: AppAssembly) {
        self.assembly = assembly
    }

    // ⚠️ 테스트용: true로 변경하면 Xcode 미설치 상태를 시뮬레이션
    private let simulateNoXcode = true

    func start() async {
        isCheckingEnvironment = true
        if simulateNoXcode {
            environmentStatus = EnvironmentStatus(
                xcodeInstalled: false,
                xcodePath: nil,
                xcodeVersion: nil,
                commandLineToolsInstalled: false,
                availableRuntimes: []
            )
        } else {
            environmentStatus = await assembly.environmentCheckUseCase().check()
        }
        isCheckingEnvironment = false

        guard environmentStatus?.isReady == true else { return }

        do {
            deviceListViewModel = try await assembly.deviceListViewModel()
            buildListViewModel = try await assembly.buildListViewModel()
            settingsViewModel = assembly.settingsViewModel()
            iosVersionViewModel = try await assembly.iosVersionViewModel()
            isReady = true

            // 디스크 사용량 등 iOS 버전 데이터를 백그라운드에서 미리 로드
            Task { await iosVersionViewModel?.onAppear() }
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
