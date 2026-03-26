import Foundation
import ShellKit
import SimulatorDomain
import SimulatorDomainInterface
import BuildDomain
import BuildDomainInterface
import EnvironmentDomain
import DeviceFeature
import BuildFeature
import SettingsFeature

/// DI 조립 - Coordinator에서 ViewModel 생성 시 사용
/// elecle-ios의 Component 패턴을 따라 전체 의존성 그래프를 명시적으로 조립
@MainActor
final class AppAssembly {

    private let defaultFolderId = "1GC85ktjO9OInB5IEVf7Wzd3laLuTegTs"

    // MARK: - Shared Instances

    private var _shell: ShellService?
    private let fileRepository = FileRepository()
    private let keychainRepository = KeychainRepository()

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

    func buildUseCase() throws -> (any BuildUseCaseInterface)? {
        guard let keyData = try keychainRepository.retrieveServiceAccountJSON() else {
            return nil
        }
        let driveRepo = try GoogleDriveRepository(serviceAccountJSON: keyData)
        let component = BuildUseCaseComponent(
            buildRepository: driveRepo,
            fileRepository: fileRepository
        )
        return BuildUseCase(dependency: component)
    }

    /// Google Drive 미설정 시에도 로컬 빌드 관리가 가능한 UseCase
    func buildUseCaseWithFallback() throws -> any BuildUseCaseInterface {
        if let useCase = try buildUseCase() { return useCase }
        // Drive 미설정 시 빈 repo 사용 (로컬 기능만 동작)
        let component = BuildUseCaseComponent(
            buildRepository: NullBuildRepository(),
            fileRepository: fileRepository
        )
        return BuildUseCase(dependency: component)
    }

    // MARK: - Environment

    func environmentCheckUseCase() -> EnvironmentCheckUseCase {
        EnvironmentCheckUseCase()
    }

    // MARK: - ViewModels

    func deviceListViewModel() async throws -> DeviceListViewModel {
        DeviceListViewModel(useCase: try await simulatorUseCase())
    }

    func buildListViewModel() async throws -> BuildListViewModel {
        let simUseCase = try await simulatorUseCase()
        let buildUC = try buildUseCaseWithFallback()
        let isDriveConfigured = (try? keychainRepository.retrieveServiceAccountJSON()) != nil
        return BuildListViewModel(
            buildUseCase: buildUC,
            simulatorUseCase: simUseCase,
            folderId: defaultFolderId,
            isDriveConfigured: isDriveConfigured
        )
    }

    func settingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            keychainRepository: keychainRepository,
            environmentCheckUseCase: environmentCheckUseCase(),
            defaultFolderId: defaultFolderId
        )
    }
}

// MARK: - Null Build Repository (Drive 미설정 시 fallback)

private struct NullBuildRepository: BuildRepositoryInterface {
    func listFiles(folderId: String) async throws -> [RemoteFile] { [] }
    func downloadFile(fileId: String, to destination: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> URL {
        throw GoogleDriveError.downloadFailed
    }
}
