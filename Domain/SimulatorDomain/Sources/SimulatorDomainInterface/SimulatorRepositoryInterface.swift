import Foundation

/// Repository 프로토콜 - UseCase에서 사용, Data 레이어에서 구현
public protocol SimulatorRepositoryInterface: Sendable {
    func listDevices() async throws -> [SimulatorDevice]
    func listRuntimes() async throws -> [SimulatorRuntime]
    func listDeviceTypes() async throws -> [SimulatorDeviceType]

    func createDevice(name: String, typeIdentifier: String, runtimeIdentifier: String) async throws -> String
    func bootDevice(udid: String) async throws
    func shutdownDevice(udid: String) async throws
    func deleteDevice(udid: String) async throws

    func installApp(udid: String, appPath: String) async throws
    func launchApp(udid: String, bundleId: String) async throws
    func openURL(udid: String, url: String) async throws
    func openSimulatorApp() async throws
}
