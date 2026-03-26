import Foundation

/// UseCase 프로토콜 - Feature 레이어에서 이 인터페이스에만 의존
public protocol SimulatorUseCaseInterface: Sendable {
    func fetchDevices() async throws -> [SimulatorDevice]
    func fetchRuntimes() async throws -> [SimulatorRuntime]
    func fetchDeviceTypes() async throws -> [SimulatorDeviceType]

    func createDevice(name: String, deviceType: SimulatorDeviceType, runtime: SimulatorRuntime) async throws -> String
    func bootDevice(udid: String) async throws
    func shutdownDevice(udid: String) async throws
    func deleteDevice(udid: String) async throws

    func installApp(udid: String, appPath: URL) async throws
    func launchApp(udid: String, bundleId: String) async throws
    func openURL(udid: String, url: String) async throws
}
