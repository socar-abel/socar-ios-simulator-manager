import Foundation

public struct SimulatorDeviceType: Identifiable, Hashable, Sendable {
    public let identifier: String
    public let name: String
    public let productFamily: String?
    public let minRuntimeVersionString: String?

    public var id: String { identifier }
    public var isIPhone: Bool { productFamily == "iPhone" || name.contains("iPhone") }
    public var isIPad: Bool { productFamily == "iPad" || name.contains("iPad") }

    /// 최소 런타임 버전을 비교 가능한 숫자 배열로 변환 (예: "17.0.0" → [17, 0, 0])
    public var minRuntimeVersionComponents: [Int]? {
        guard let version = minRuntimeVersionString else { return nil }
        let components = version.split(separator: ".").compactMap { Int($0) }
        return components.isEmpty ? nil : components
    }

    public init(identifier: String, name: String, productFamily: String?, minRuntimeVersionString: String? = nil) {
        self.identifier = identifier
        self.name = name
        self.productFamily = productFamily
        self.minRuntimeVersionString = minRuntimeVersionString
    }
}
