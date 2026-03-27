import Foundation
import Domain

@Observable
public final class DeviceListViewModel {

    public private(set) var devices: [SimulatorDevice] = []
    public private(set) var runtimes: [SimulatorIOSVersion] = []
    public private(set) var deviceTypes: [SimulatorDeviceType] = []
    public private(set) var isLoading = false
    public private(set) var isDeleting = false
    public var errorMessage: String?

    public var selectedDevice: SimulatorDevice?

    // MARK: - Multi Selection

    public var selectedUDIDs: Set<String> = []
    public var isMultiSelectMode = false

    public var selectedCount: Int { selectedUDIDs.count }

    public func toggleSelection(_ device: SimulatorDevice) {
        if selectedUDIDs.contains(device.udid) {
            selectedUDIDs.remove(device.udid)
        } else {
            selectedUDIDs.insert(device.udid)
        }
    }

    public func isSelected(_ device: SimulatorDevice) -> Bool {
        selectedUDIDs.contains(device.udid)
    }

    public func selectAll() {
        selectedUDIDs = Set(devices.map(\.udid))
    }

    public func deselectAll() {
        selectedUDIDs.removeAll()
    }

    public func exitMultiSelectMode() {
        isMultiSelectMode = false
        selectedUDIDs.removeAll()
    }

    // MARK: - Dependencies

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
            async let r = useCase.fetchIOSVersions()
            async let t = useCase.fetchDeviceTypes()
            devices = try await d
            runtimes = try await r
            deviceTypes = try await t
            // 선택된 디바이스를 새 목록에서 갱신
            if let selected = selectedDevice {
                selectedDevice = devices.first { $0.udid == selected.udid }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func boot(udid: String) async {
        errorMessage = nil
        do {
            try await useCase.bootDevice(udid: udid)
            try? await useCase.bringSimulatorToFront()
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

    public func bringSimulatorToFront() async throws {
        try await useCase.bringSimulatorToFront()
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

    public func deleteSelected() async {
        guard !selectedUDIDs.isEmpty else { return }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        var failCount = 0
        for udid in selectedUDIDs {
            do {
                try await useCase.deleteDevice(udid: udid)
            } catch {
                failCount += 1
            }
        }

        let deletedCount = selectedUDIDs.count - failCount
        selectedUDIDs.removeAll()
        selectedDevice = nil
        isMultiSelectMode = false
        await refreshAll()

        if failCount > 0 {
            errorMessage = "\(deletedCount)개 삭제 완료, \(failCount)개 삭제 실패"
        }
    }

    public func createDevice(
        name: String,
        deviceType: SimulatorDeviceType,
        runtime: SimulatorIOSVersion
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
