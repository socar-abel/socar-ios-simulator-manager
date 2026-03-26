import Foundation

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
}
