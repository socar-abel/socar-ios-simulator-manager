import Foundation
import Core
import Domain

@MainActor
@Observable
public final class DeviceListViewModel {

    public private(set) var devices: [SimulatorDevice] = []
    public private(set) var runtimes: [SimulatorIOSVersion] = []
    public private(set) var deviceTypes: [SimulatorDeviceType] = []
    public private(set) var deviceProfiles: [String: DeviceTypeProfile] = [:]
    public private(set) var isLoading = false
    public private(set) var isDeleting = false
    public private(set) var deletingDeviceName: String?
    public var isCreating = false
    public var creatingDeviceName: String?
    public var errorMessage: String?
    public var successMessage: String?

    public var selectedDevice: SimulatorDevice?

    // MARK: - Sort & Filter

    public var sortOption: DeviceSortOption = .nameDesc
    public var notchFilter: NotchFilter = .all

    public var filteredAndSortedDevices: [SimulatorDevice] {
        DeviceSorter.sort(
            devices: devices,
            profiles: deviceProfiles,
            option: sortOption,
            filter: notchFilter
        )
    }

    public func profile(for device: SimulatorDevice) -> DeviceTypeProfile? {
        guard let typeId = device.deviceTypeIdentifier else { return nil }
        return deviceProfiles[typeId]
    }

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
        // 프로필은 한 번만 로드
        if deviceProfiles.isEmpty {
            deviceProfiles = (try? await useCase.fetchDeviceTypeProfiles()) ?? [:]
        }
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
            await refreshUntilState(udid: udid, expectedState: "Booted")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func shutdown(udid: String) async {
        errorMessage = nil
        do {
            try await useCase.shutdownDevice(udid: udid)
            await refreshUntilState(udid: udid, expectedState: "Shutdown")
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// 상태가 반영될 때까지 최대 폴링
    private func refreshUntilState(udid: String, expectedState: String) async {
        for _ in 0..<AppConstants.Polling.deviceStateMaxAttempts {
            await refreshAll()
            if devices.first(where: { $0.udid == udid })?.state == expectedState {
                return
            }
            try? await Task.sleep(for: .milliseconds(AppConstants.Polling.deviceStateIntervalMs))
        }
        // 폴링 실패 시에도 한 번 더 새로고침
        await refreshAll()
    }

    public func bringSimulatorToFront() async throws {
        try await useCase.bringSimulatorToFront()
    }

    public func renameDevice(udid: String, newName: String) async {
        errorMessage = nil
        do {
            try await useCase.renameDevice(udid: udid, newName: newName)
            await refreshAll()
            successMessage = "디바이스 이름이 변경되었습니다."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Location

    public func setLocation(udid: String, latitude: Double, longitude: Double) async {
        errorMessage = nil
        do {
            try await useCase.setLocation(udid: udid, latitude: latitude, longitude: longitude)
            successMessage = "위치가 설정되었습니다."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Push Notification

    public func sendPush(udid: String, bundleId: String, payload: String) async {
        // 에러 무시 — 여러 bundle ID로 시도하므로 일부 실패 가능
        try? await useCase.sendPushNotification(udid: udid, bundleId: bundleId, payload: payload)
    }

    public func clearLocation(udid: String) async {
        errorMessage = nil
        do {
            try await useCase.clearLocation(udid: udid)
            successMessage = "위치가 초기화되었습니다."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func delete(udid: String) async {
        let deviceName = devices.first { $0.udid == udid }?.name ?? "디바이스"
        isDeleting = true
        deletingDeviceName = deviceName
        errorMessage = nil
        defer {
            isDeleting = false
            deletingDeviceName = nil
        }

        do {
            try await useCase.deleteDevice(udid: udid)
            selectedDevice = nil
            await refreshAll()
            successMessage = "'\(deviceName)'이(가) 삭제되었습니다."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteSelected() async {
        guard !selectedUDIDs.isEmpty else { return }
        let count = selectedUDIDs.count
        isDeleting = true
        deletingDeviceName = "\(count)개 디바이스"
        errorMessage = nil
        defer {
            isDeleting = false
            deletingDeviceName = nil
        }

        var failedNames: [String] = []
        for udid in selectedUDIDs {
            let name = devices.first { $0.udid == udid }?.name ?? udid
            do {
                try await useCase.deleteDevice(udid: udid)
            } catch {
                failedNames.append(name)
            }
        }

        let deletedCount = count - failedNames.count
        selectedUDIDs.removeAll()
        selectedDevice = nil
        isMultiSelectMode = false
        await refreshAll()

        if !failedNames.isEmpty {
            errorMessage = "\(deletedCount)개 삭제 완료. 삭제 실패: \(failedNames.joined(separator: ", "))"
        } else {
            successMessage = "\(deletedCount)개 디바이스가 삭제되었습니다."
        }
    }

    public func createDevice(
        name: String,
        deviceType: SimulatorDeviceType,
        runtime: SimulatorIOSVersion
    ) async throws {
        isCreating = true
        creatingDeviceName = name
        defer {
            isCreating = false
            creatingDeviceName = nil
        }
        _ = try await useCase.createDevice(
            name: name,
            deviceType: deviceType,
            runtime: runtime
        )
        await refreshAll()
        successMessage = "'\(name)'이(가) 생성되었습니다."
    }

    public func installApp(udid: String, appPath: URL) async throws {
        try await useCase.installApp(udid: udid, appPath: appPath)
    }

    public func launchApp(udid: String, bundleId: String) async throws {
        try await useCase.launchApp(udid: udid, bundleId: bundleId)
    }

    public func openURL(udid: String, url: String) async throws {
        try await useCase.openURL(udid: udid, url: url)
    }

    public func dismissError() {
        errorMessage = nil
    }

    public func dismissSuccess() {
        successMessage = nil
    }
}

