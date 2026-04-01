import Foundation

/// 디바이스 정렬/필터링 도메인 서비스
public enum DeviceSorter {

    /// 디바이스 목록을 필터 + 정렬하여 반환
    public static func sort(
        devices: [SimulatorDevice],
        profiles: [String: DeviceTypeProfile],
        option: DeviceSortOption,
        filter: NotchFilter
    ) -> [SimulatorDevice] {
        var result = devices

        // 필터
        switch filter {
        case .all:
            break
        case .notchOnly:
            result = result.filter { profile(for: $0, in: profiles)?.hasNotch == true }
        case .noNotchOnly:
            result = result.filter { profile(for: $0, in: profiles)?.hasNotch == false }
        }

        // 정렬
        result.sort { a, b in
            switch option {
            case .nameAsc:
                return a.name.localizedStandardCompare(b.name) == .orderedAscending
            case .nameDesc:
                return a.name.localizedStandardCompare(b.name) == .orderedDescending
            case .runtimeNewest:
                return (a.runtimeIdentifier ?? "") > (b.runtimeIdentifier ?? "")
            case .runtimeOldest:
                return (a.runtimeIdentifier ?? "") < (b.runtimeIdentifier ?? "")
            case .screenWidthRatioAsc:
                let ra = profile(for: a, in: profiles)?.widthRatio
                let rb = profile(for: b, in: profiles)?.widthRatio
                if ra == nil && rb == nil {
                    return a.name.localizedStandardCompare(b.name) == .orderedAscending
                }
                return (ra ?? .greatestFiniteMagnitude) < (rb ?? .greatestFiniteMagnitude)
            case .screenWidthRatioDesc:
                let ra = profile(for: a, in: profiles)?.widthRatio
                let rb = profile(for: b, in: profiles)?.widthRatio
                if ra == nil && rb == nil {
                    return a.name.localizedStandardCompare(b.name) == .orderedDescending
                }
                return (ra ?? 0) > (rb ?? 0)
            }
        }
        return result
    }

    private static func profile(
        for device: SimulatorDevice,
        in profiles: [String: DeviceTypeProfile]
    ) -> DeviceTypeProfile? {
        guard let typeId = device.deviceTypeIdentifier else { return nil }
        return profiles[typeId]
    }
}

// MARK: - Sort & Filter Enums

public enum DeviceSortOption: String, CaseIterable, Sendable {
    case nameAsc = "이름순"
    case nameDesc = "이름 역순"
    case runtimeNewest = "iOS 최신순"
    case runtimeOldest = "iOS 오래된순"
    case screenWidthRatioAsc = "width 비율 좁은순"
    case screenWidthRatioDesc = "width 비율 넓은순"
}

public enum NotchFilter: String, CaseIterable, Sendable {
    case all = "전체"
    case notchOnly = "노치/다이나믹 아일랜드"
    case noNotchOnly = "노치 없음"
}
