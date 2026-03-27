import Foundation

public protocol SimulatorUseCaseDependency {
    var repository: any SimulatorRepositoryInterface { get }
}

public final class SimulatorUseCase<Dependency: SimulatorUseCaseDependency>: SimulatorUseCaseInterface {

    private let dependency: Dependency

    public init(dependency: Dependency) {
        self.dependency = dependency
    }

    public func fetchDevices() async throws -> [SimulatorDevice] {
        try await dependency.repository.listDevices()
    }

    public func fetchIOSVersions() async throws -> [SimulatorIOSVersion] {
        try await dependency.repository.listIOSVersions()
    }

    public func fetchDeviceTypes() async throws -> [SimulatorDeviceType] {
        try await dependency.repository.listDeviceTypes()
    }

    public func createDevice(
        name: String,
        deviceType: SimulatorDeviceType,
        runtime: SimulatorIOSVersion
    ) async throws -> String {
        try await dependency.repository.createDevice(
            name: name,
            typeIdentifier: deviceType.identifier,
            runtimeIdentifier: runtime.identifier
        )
    }

    public func bootDevice(udid: String) async throws {
        try await dependency.repository.openSimulatorApp()
        try await dependency.repository.bootDevice(udid: udid)
    }

    public func shutdownDevice(udid: String) async throws {
        try await dependency.repository.shutdownDevice(udid: udid)
    }

    public func deleteDevice(udid: String) async throws {
        // 부팅 상태면 먼저 종료
        let devices = try await dependency.repository.listDevices()
        if let device = devices.first(where: { $0.udid == udid }), device.isBooted {
            try await dependency.repository.shutdownDevice(udid: udid)
        }
        try await dependency.repository.deleteDevice(udid: udid)
    }

    public func renameDevice(udid: String, newName: String) async throws {
        try await dependency.repository.renameDevice(udid: udid, newName: newName)
    }

    public func installApp(udid: String, appPath: URL) async throws {
        try await dependency.repository.installApp(
            udid: udid,
            appPath: appPath.path(percentEncoded: false)
        )
    }

    public func launchApp(udid: String, bundleId: String) async throws {
        try await dependency.repository.launchApp(udid: udid, bundleId: bundleId)
    }

    public func openURL(udid: String, url: String) async throws {
        try await dependency.repository.openURL(udid: udid, url: url)
    }

    public func isAppInstalled(udid: String, bundleId: String) async throws -> Bool {
        let installedApps = try await dependency.repository.listInstalledApps(udid: udid)
        return installedApps.contains(bundleId)
    }

    public func fetchDeviceTypeProfiles() async throws -> [String: DeviceTypeProfile] {
        try await dependency.repository.loadDeviceTypeProfiles()
    }

    public func bringSimulatorToFront() async throws {
        try await dependency.repository.bringSimulatorToFront()
    }

    // MARK: - Runtime Management

    public func fetchInstalledIOSVersions() async throws -> [InstalledIOSVersion] {
        try await dependency.repository.listInstalledIOSVersions()
    }

    public func fetchDownloadableIOSVersions() async throws -> [DownloadableIOSVersion] {
        let installed = try await dependency.repository.listInstalledIOSVersions()
        let installedNames = Set(installed.map { $0.displayName })
        let all = try await dependency.repository.listDownloadableIOSVersions()
        // 이미 설치된 버전 제외, beta 제외, iOS만
        return all.filter { !installedNames.contains($0.shortName) && !$0.isBeta }
    }

    public func deleteIOSVersion(identifier: String) async throws {
        try await dependency.repository.deleteIOSVersion(identifier: identifier)
    }

    public func downloadIOSVersion(platform: String, buildVersion: String?) async throws {
        try await dependency.repository.downloadIOSVersion(platform: platform, buildVersion: buildVersion)
    }

    public func downloadIOSVersionWithProgress(
        platform: String,
        buildVersion: String?,
        onProgress: @Sendable @escaping (DownloadProgress) -> Void
    ) async throws {
        try await dependency.repository.downloadIOSVersionWithProgress(
            platform: platform,
            buildVersion: buildVersion,
            onProgress: onProgress
        )
    }

    // MARK: - Disk

    public func fetchDiskUsage() async throws -> DiskUsage {
        let runtimes = try await dependency.repository.listInstalledIOSVersions()
        let iosVersionsBytes = runtimes.reduce(Int64(0)) { $0 + $1.sizeBytes }
        let devicesBytes = try await dependency.repository.devicesDiskUsageBytes()
        return DiskUsage(iosVersionsBytes: iosVersionsBytes, devicesBytes: devicesBytes, buildsBytes: 0)
    }

    public func deleteAllUnavailableDevices() async throws {
        try await dependency.repository.deleteUnavailableDevices()
    }
}
