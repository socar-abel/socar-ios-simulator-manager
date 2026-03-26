import Foundation
import SimulatorDomainInterface

@Observable
public final class DeviceListViewModel {

    public private(set) var devices: [SimulatorDevice] = []
    public private(set) var runtimes: [SimulatorRuntime] = []
    public private(set) var deviceTypes: [SimulatorDeviceType] = []
    public private(set) var isLoading = false
    public var errorMessage: String?

    public var selectedDevice: SimulatorDevice?

    private let useCase: any SimulatorUseCaseInterface

    public init(useCase: any SimulatorUseCaseInterface) {
        self.useCase = useCase
    }

    // MARK: - Input

    public func onAppear() async {
        await refreshAll()
    }

    public func refreshAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let d = useCase.fetchDevices()
            async let r = useCase.fetchRuntimes()
            async let t = useCase.fetchDeviceTypes()
            devices = try await d
            runtimes = try await r
            deviceTypes = try await t
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func boot(udid: String) async {
        errorMessage = nil
        do {
            try await useCase.bootDevice(udid: udid)
            await refreshAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func shutdown(udid: String) async {
        errorMessage = nil
        do {
            try await useCase.shutdownDevice(udid: udid)
            await refreshAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func delete(udid: String) async {
        errorMessage = nil
        do {
            try await useCase.deleteDevice(udid: udid)
            selectedDevice = nil
            await refreshAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func createDevice(
        name: String,
        deviceType: SimulatorDeviceType,
        runtime: SimulatorRuntime
    ) async throws {
        _ = try await useCase.createDevice(
            name: name,
            deviceType: deviceType,
            runtime: runtime
        )
        await refreshAll()
    }

    public func installApp(udid: String, appPath: URL) async throws {
        try await useCase.installApp(udid: udid, appPath: appPath)
    }

    public func launchApp(udid: String, bundleId: String) async throws {
        try await useCase.launchApp(udid: udid, bundleId: bundleId)
    }

    public func dismissError() {
        errorMessage = nil
    }
}
