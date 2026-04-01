import Foundation

/// UseCase 프로토콜 - Feature 레이어에서 이 인터페이스에만 의존
public protocol SimulatorUseCaseInterface: Sendable {
    func fetchDevices() async throws -> [SimulatorDevice]
    func fetchIOSVersions() async throws -> [SimulatorIOSVersion]
    func fetchDeviceTypes() async throws -> [SimulatorDeviceType]

    func createDevice(name: String, deviceType: SimulatorDeviceType, runtime: SimulatorIOSVersion) async throws -> String
    func bootDevice(udid: String) async throws
    func shutdownDevice(udid: String) async throws
    func deleteDevice(udid: String) async throws
    func renameDevice(udid: String, newName: String) async throws

    func installApp(udid: String, appPath: URL) async throws
    func launchApp(udid: String, bundleId: String) async throws
    func openURL(udid: String, url: String) async throws
    func isAppInstalled(udid: String, bundleId: String) async throws -> Bool
    func bringSimulatorToFront() async throws
    func fetchDeviceTypeProfiles() async throws -> [String: DeviceTypeProfile]

    // iOS 버전 관리
    func fetchInstalledIOSVersions() async throws -> [InstalledIOSVersion]
    func fetchDownloadableIOSVersions() async throws -> [DownloadableIOSVersion]
    func deleteIOSVersion(identifier: String) async throws
    func downloadIOSVersion(platform: String, buildVersion: String?) async throws
    func downloadIOSVersionWithProgress(
        platform: String,
        buildVersion: String?,
        onProgress: @Sendable @escaping (DownloadProgress) -> Void
    ) async throws

    // 위치
    func setLocation(udid: String, latitude: Double, longitude: Double) async throws
    func clearLocation(udid: String) async throws

    // 디스크
    func fetchDiskUsage() async throws -> DiskUsage
    func deleteAllUnavailableDevices() async throws
}
