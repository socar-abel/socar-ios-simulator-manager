import Foundation
import SimulatorDomainInterface
import ShellKit

public protocol SimulatorRepositoryDependency {
    var shell: ShellService { get }
}

public final class SimulatorRepository<Dependency: SimulatorRepositoryDependency>: SimulatorRepositoryInterface {

    private let dependency: Dependency

    public init(dependency: Dependency) {
        self.dependency = dependency
    }

    public func listDevices() async throws -> [SimulatorDevice] {
        let result = try await dependency.shell.simctl("list", "devices", "--json")
        guard result.isSuccess, let data = result.stdout.data(using: .utf8) else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }

        let response = try JSONDecoder().decode(SimctlDevicesResponse.self, from: data)
        var allDevices: [SimulatorDevice] = []

        for (runtimeKey, deviceList) in response.devices {
            for raw in deviceList where raw.isAvailable {
                allDevices.append(SimulatorDevice(
                    udid: raw.udid,
                    name: raw.name,
                    state: raw.state,
                    isAvailable: raw.isAvailable,
                    deviceTypeIdentifier: raw.deviceTypeIdentifier,
                    runtimeIdentifier: runtimeKey
                ))
            }
        }
        return allDevices.sorted { $0.name < $1.name }
    }

    public func listRuntimes() async throws -> [SimulatorRuntime] {
        let result = try await dependency.shell.simctl("list", "runtimes", "--json")
        guard result.isSuccess, let data = result.stdout.data(using: .utf8) else {
            return []
        }
        let response = try JSONDecoder().decode(SimctlRuntimesResponse.self, from: data)
        return response.runtimes
            .filter { $0.isAvailable }
            .map { SimulatorRuntime(
                identifier: $0.identifier,
                name: $0.name,
                version: $0.version,
                isAvailable: $0.isAvailable
            )}
    }

    public func listDeviceTypes() async throws -> [SimulatorDeviceType] {
        let result = try await dependency.shell.simctl("list", "devicetypes", "--json")
        guard result.isSuccess, let data = result.stdout.data(using: .utf8) else {
            return []
        }
        let response = try JSONDecoder().decode(SimctlDeviceTypesResponse.self, from: data)
        return response.devicetypes.map {
            SimulatorDeviceType(
                identifier: $0.identifier,
                name: $0.name,
                productFamily: $0.productFamily
            )
        }
    }

    public func createDevice(
        name: String,
        typeIdentifier: String,
        runtimeIdentifier: String
    ) async throws -> String {
        let result = try await dependency.shell.simctlArgs([
            "create", name, typeIdentifier, runtimeIdentifier,
        ])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func bootDevice(udid: String) async throws {
        let result = try await dependency.shell.simctlArgs(["boot", udid])
        guard result.isSuccess || result.stderr.contains("current state: Booted") else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func shutdownDevice(udid: String) async throws {
        let result = try await dependency.shell.simctlArgs(["shutdown", udid])
        guard result.isSuccess || result.stderr.contains("current state: Shutdown") else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func deleteDevice(udid: String) async throws {
        let result = try await dependency.shell.simctlArgs(["delete", udid])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func installApp(udid: String, appPath: String) async throws {
        let result = try await dependency.shell.simctlArgs(["install", udid, appPath])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func launchApp(udid: String, bundleId: String) async throws {
        let result = try await dependency.shell.simctlArgs(["launch", udid, bundleId])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func openURL(udid: String, url: String) async throws {
        let result = try await dependency.shell.simctlArgs(["openurl", udid, url])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func openSimulatorApp() async throws {
        _ = try await dependency.shell.run(
            executable: "/usr/bin/open",
            arguments: ["-a", "Simulator"]
        )
    }
}

public enum SimulatorRepositoryError: LocalizedError {
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let reason):
            return "시뮬레이터 명령 실패: \(reason)"
        }
    }
}
