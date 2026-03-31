import Foundation
import Core
import Domain

/// simctl JSON 응답을 디코딩하기 위한 DTO (Data Transfer Objects)
/// Domain Entity와 분리하여 외부 JSON 구조 변경에 대응

// MARK: - Devices

struct SimctlDevicesResponse: Codable {
    let devices: [String: [SimctlDeviceDTO]]
}

struct SimctlDeviceDTO: Codable {
    let udid: String
    let name: String
    let state: String
    let isAvailable: Bool
    let deviceTypeIdentifier: String?
}

// MARK: - Runtimes

struct SimctlIOSVersionsResponse: Codable {
    let runtimes: [SimctlIOSVersionDTO]
}

struct SimctlIOSVersionDTO: Codable {
    let identifier: String
    let name: String
    let version: String
    let isAvailable: Bool
    let platform: String?
}

// MARK: - Device Types

struct SimctlDeviceTypesResponse: Codable {
    let devicetypes: [SimctlDeviceTypeDTO]
}

struct SimctlDeviceTypeDTO: Codable {
    let identifier: String
    let name: String
    let productFamily: String?
    let minRuntimeVersionString: String?
}

// MARK: - Runtime Detail (simctl runtime list -j)

struct SimctlIOSVersionDetailDTO: Codable {
    let identifier: String
    let runtimeIdentifier: String?
    let version: String?
    let sizeBytes: Int64?
    let deletable: Bool?
    let state: String?
    let lastUsedAt: String?
    let platformIdentifier: String?
}

// MARK: - Apple CDN Downloadable Index

struct DVTDownloadableIndex: Codable {
    let downloadables: [DVTDownloadableItem]
}

struct DVTDownloadableItem: Codable {
    let name: String
    let version: String
    let fileSize: Int64
    let source: String?
    let contentType: String?
    let simulatorVersion: DVTSimulatorVersion?
    let hostRequirements: DVTHostRequirements?

    /// 현재 macOS에서 다운로드 가능한지 판별
    var isDownloadableOnCurrentMac: Bool {
        // contentType이 package(구식 포맷)이면 불가
        if contentType == "package" { return false }

        // maxHostVersion이 현재 macOS보다 낮으면 불가
        if let maxHost = hostRequirements?.maxHostVersion {
            let currentMacOS = ProcessInfo.processInfo.operatingSystemVersion
            let currentStr = "\(currentMacOS.majorVersion).\(currentMacOS.minorVersion).\(currentMacOS.patchVersion)"
            if compareVersions(maxHost, currentStr) == .orderedAscending {
                return false
            }
        }

        // iOS 시뮬레이터 major version이 16 미만이면 최신 Xcode에서 지원하지 않음
        let majorVersion = Int(version.split(separator: ".").first ?? "0") ?? 0
        if majorVersion > 0 && majorVersion < 16 {
            return false
        }

        return true
    }

    /// 주어진 SDK 최대 버전보다 높은 iOS 버전인지 확인
    func isCompatibleWithSDK(maxMajor: Int) -> Bool {
        let majorVersion = Int(version.split(separator: ".").first ?? "0") ?? 0
        return majorVersion <= maxMajor
    }

    private func compareVersions(_ v1: String, _ v2: String) -> ComparisonResult {
        let parts1 = v1.split(separator: ".").compactMap { Int($0) }
        let parts2 = v2.split(separator: ".").compactMap { Int($0) }
        let count = max(parts1.count, parts2.count)
        for i in 0..<count {
            let a = i < parts1.count ? parts1[i] : 0
            let b = i < parts2.count ? parts2[i] : 0
            if a < b { return .orderedAscending }
            if a > b { return .orderedDescending }
        }
        return .orderedSame
    }
}

struct DVTSimulatorVersion: Codable {
    let buildUpdate: String?
    let version: String?
}

struct DVTHostRequirements: Codable {
    let maxHostVersion: String?
}
