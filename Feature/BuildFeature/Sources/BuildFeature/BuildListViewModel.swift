import Foundation
import BuildDomainInterface
import SimulatorDomainInterface

@Observable
public final class BuildListViewModel {

    public private(set) var remoteBuilds: [BuildInfo] = []
    public private(set) var isLoadingRemote = false
    public private(set) var remoteError: String?
    public private(set) var downloadingFileId: String?
    public private(set) var downloadProgress: Double = 0
    public private(set) var errorMessage: String?
    public private(set) var isDriveConfigured: Bool

    private let buildUseCase: any BuildUseCaseInterface
    private let simulatorUseCase: any SimulatorUseCaseInterface
    private let folderId: String

    public init(
        buildUseCase: any BuildUseCaseInterface,
        simulatorUseCase: any SimulatorUseCaseInterface,
        folderId: String,
        isDriveConfigured: Bool
    ) {
        self.buildUseCase = buildUseCase
        self.simulatorUseCase = simulatorUseCase
        self.folderId = folderId
        self.isDriveConfigured = isDriveConfigured
    }

    // MARK: - Input

    public func onAppear() async {
        if isDriveConfigured {
            await loadRemoteBuilds()
        }
    }

    public func loadRemoteBuilds() async {
        guard isDriveConfigured else { return }
        isLoadingRemote = true
        remoteError = nil
        defer { isLoadingRemote = false }

        do {
            remoteBuilds = try await buildUseCase.listRemoteBuilds(folderId: folderId)
        } catch {
            remoteError = error.localizedDescription
        }
    }

    public func localApps() -> [URL] {
        buildUseCase.listLocalApps()
    }

    public func downloadBuild(_ build: BuildInfo) async {
        downloadingFileId = build.id
        downloadProgress = 0
        defer { downloadingFileId = nil }

        do {
            let zipURL = try await buildUseCase.downloadBuild(
                fileId: build.id,
                fileName: build.fileName
            ) { [weak self] progress in
                Task { @MainActor in self?.downloadProgress = progress }
            }
            _ = try await buildUseCase.extractZIP(at: zipURL)
            try? FileManager.default.removeItem(at: zipURL)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteBuild(at path: URL) {
        try? buildUseCase.deleteLocalBuild(at: path)
    }

    public func installOnDevice(appURL: URL, udid: String) async throws {
        try await simulatorUseCase.installApp(udid: udid, appPath: appURL)
    }

    public func bootedDevices() async -> [SimulatorDevice] {
        (try? await simulatorUseCase.fetchDevices().filter(\.isBooted)) ?? []
    }
}
