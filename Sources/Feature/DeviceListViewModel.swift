import Foundation
import Domain

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
        var result = devices

        // 필터
        switch notchFilter {
        case .all: break
        case .notchOnly:
            result = result.filter { profile(for: $0)?.hasNotch == true }
        case .noNotchOnly:
            result = result.filter { profile(for: $0)?.hasNotch != true }
        }

        // 정렬
        result.sort { a, b in
            switch sortOption {
            case .nameAsc:
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .nameDesc:
                return a.name.localizedStandardCompare(b.name) == .orderedDescending
            case .runtimeNewest:
                return (a.runtimeIdentifier ?? "") > (b.runtimeIdentifier ?? "")
            case .runtimeOldest:
                return (a.runtimeIdentifier ?? "") < (b.runtimeIdentifier ?? "")
            case .screenWidthAsc:
                return (profile(for: a)?.logicalWidth ?? 0) < (profile(for: b)?.logicalWidth ?? 0)
            case .screenWidthDesc:
                return (profile(for: a)?.logicalWidth ?? 0) > (profile(for: b)?.logicalWidth ?? 0)
            }
        }
        return result
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

    /// 상태가 반영될 때까지 최대 5회 폴링
    private func refreshUntilState(udid: String, expectedState: String) async {
        for _ in 0..<5 {
            await refreshAll()
            if devices.first(where: { $0.udid == udid })?.state == expectedState {
                return
            }
            try? await Task.sleep(for: .milliseconds(500))
        }
    }

    public func bringSimulatorToFront() async throws {
        try await useCase.bringSimulatorToFront()
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

        var failCount = 0
        for udid in selectedUDIDs {
            do {
                try await useCase.deleteDevice(udid: udid)
            } catch {
                failCount += 1
            }
        }

        let deletedCount = count - failCount
        selectedUDIDs.removeAll()
        selectedDevice = nil
        isMultiSelectMode = false
        await refreshAll()

        if failCount > 0 {
            errorMessage = "\(deletedCount)개 삭제 완료, \(failCount)개 삭제 실패"
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

// MARK: - Sort & Filter Enums

public enum DeviceSortOption: String, CaseIterable {
    case nameAsc = "이름순"
    case nameDesc = "이름 역순"
    case runtimeNewest = "iOS 최신순"
    case runtimeOldest = "iOS 오래된순"
    case screenWidthAsc = "화면 좁은순"
    case screenWidthDesc = "화면 넓은순"
}

public enum NotchFilter: String, CaseIterable {
    case all = "전체"
    case notchOnly = "노치/다이나믹 아일랜드"
    case noNotchOnly = "노치 없음"
}
