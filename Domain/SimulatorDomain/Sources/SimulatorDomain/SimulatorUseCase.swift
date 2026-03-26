import Foundation
import SimulatorDomainInterface

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

    public func fetchRuntimes() async throws -> [SimulatorRuntime] {
        try await dependency.repository.listRuntimes()
    }

    public func fetchDeviceTypes() async throws -> [SimulatorDeviceType] {
        try await dependency.repository.listDeviceTypes()
    }

    public func createDevice(
        name: String,
        deviceType: SimulatorDeviceType,
        runtime: SimulatorRuntime
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
}
