import Foundation

public struct SimulatorIOSVersion: Identifiable, Hashable, Sendable {
    public let identifier: String
    public let name: String
    public let version: String
    public let isAvailable: Bool

    public var id: String { identifier }
    public var isIOS: Bool { identifier.contains("iOS") }

    /// 버전을 비교 가능한 숫자 배열로 변환 (예: "17.0.1" → [17, 0, 1])
    public var versionComponents: [Int] {
        version.split(separator: ".").compactMap { Int($0) }
    }

    /// 이 런타임이 주어진 최소 버전 이상인지 확인
    public func isCompatible(withMinVersion minComponents: [Int]) -> Bool {
        let lhs = versionComponents
        let maxLen = max(lhs.count, minComponents.count)
        for i in 0..<maxLen {
            let l = i < lhs.count ? lhs[i] : 0
            let r = i < minComponents.count ? minComponents[i] : 0
            if l > r { return true }
            if l < r { return false }
        }
        return true // 동일한 경우
    }

    public init(identifier: String, name: String, version: String, isAvailable: Bool) {
        self.identifier = identifier
        self.name = name
        self.version = version
        self.isAvailable = isAvailable
    }
}
