import Foundation
import Shell
import SimulatorDomain
import SimulatorDomainInterface
import SimulatorData
import BuildDomain
import BuildDomainInterface
import BuildData
import EnvironmentDomain
import EnvironmentData
import DeviceFeature
import BuildFeature
import SettingsFeature
import IOSVersionFeature

/// DI 조립 - Coordinator에서 ViewModel 생성 시 사용
@MainActor
final class AppAssembly {

    // MARK: - Shared Instances

    private var _shell: ShellService?
    private let fileRepository = FileRepository()

    // MARK: - Shell

    func shell() async throws -> ShellService {
        if let existing = _shell { return existing }
        let shell = try await ShellService()
        _shell = shell
        return shell
    }

    // MARK: - Simulator

    func simulatorUseCase() async throws -> any SimulatorUseCaseInterface {
        let sh = try await shell()
        let repoComponent = SimulatorRepositoryComponent(shell: sh)
        let repository = SimulatorRepository(dependency: repoComponent)
        let useCaseComponent = SimulatorUseCaseComponent(repository: repository)
        return SimulatorUseCase(dependency: useCaseComponent)
    }

    // MARK: - Build

    func buildUseCase() -> any BuildUseCaseInterface {
        let component = BuildUseCaseComponent(fileRepository: fileRepository)
        return BuildUseCase(dependency: component)
    }

    // MARK: - Environment

    func environmentCheckUseCase() -> EnvironmentCheckUseCase {
        let repository = EnvironmentRepository()
        return EnvironmentCheckUseCase(repository: repository)
    }

    // MARK: - ViewModels

    func deviceListViewModel() async throws -> DeviceListViewModel {
        DeviceListViewModel(useCase: try await simulatorUseCase())
    }

    func buildListViewModel() async throws -> BuildListViewModel {
        BuildListViewModel(
            buildUseCase: buildUseCase(),
            simulatorUseCase: try await simulatorUseCase()
        )
    }

    func iosVersionViewModel() async throws -> IOSVersionViewModel {
        IOSVersionViewModel(useCase: try await simulatorUseCase())
    }

    func settingsViewModel() -> SettingsViewModel {
        SettingsViewModel(environmentCheckUseCase: environmentCheckUseCase())
    }
}
