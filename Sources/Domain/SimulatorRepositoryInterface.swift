import Foundation

/// Repository 프로토콜 - UseCase에서 사용, Data 레이어에서 구현
public protocol SimulatorRepositoryInterface: Sendable {
    func listDevices() async throws -> [SimulatorDevice]
    func listIOSVersions() async throws -> [SimulatorIOSVersion]
    func listDeviceTypes() async throws -> [SimulatorDeviceType]

    func createDevice(name: String, typeIdentifier: String, runtimeIdentifier: String) async throws -> String
    func bootDevice(udid: String) async throws
    func shutdownDevice(udid: String) async throws
    func deleteDevice(udid: String) async throws
    func renameDevice(udid: String, newName: String) async throws

    func installApp(udid: String, appPath: String) async throws
    func launchApp(udid: String, bundleId: String) async throws
    func openURL(udid: String, url: String) async throws
    func openSimulatorApp() async throws
    func loadDeviceTypeProfiles() async throws -> [String: DeviceTypeProfile]
    func listInstalledApps(udid: String) async throws -> Set<String>
    func bringSimulatorToFront() async throws

    // iOS 버전 관리
    func listInstalledIOSVersions() async throws -> [InstalledIOSVersion]
    func listDownloadableIOSVersions() async throws -> [DownloadableIOSVersion]
    func deleteIOSVersion(identifier: String) async throws
    func downloadIOSVersion(platform: String, buildVersion: String?) async throws
    func downloadIOSVersionWithProgress(
        platform: String,
        buildVersion: String?,
        onProgress: @Sendable @escaping (DownloadProgress) -> Void
    ) async throws

    // 디스크
    func devicesDiskUsageBytes() async throws -> Int64
    func deleteUnavailableDevices() async throws
}
