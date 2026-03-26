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

struct SimctlRuntimesResponse: Codable {
    let runtimes: [SimctlRuntimeDTO]
}

struct SimctlRuntimeDTO: Codable {
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
