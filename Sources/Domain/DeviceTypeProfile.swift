import Foundation

/// 디바이스 타입의 물리적 프로필 (화면 크기, 노치 여부 등)
public struct DeviceTypeProfile: Sendable {
    public let identifier: String
    public let screenWidth: Int
    public let screenHeight: Int
    public let screenScale: Int
    public let hasNotch: Bool  // 노치 또는 다이나믹 아일랜드

    /// 논리적 화면 너비 (pt)
    public var logicalWidth: Double {
        guard screenScale > 0 else { return Double(screenWidth) }
        return Double(screenWidth) / Double(screenScale)
    }

    /// 논리적 화면 높이 (pt)
    public var logicalHeight: Double {
        guard screenScale > 0 else { return Double(screenHeight) }
        return Double(screenHeight) / Double(screenScale)
    }

    /// 가로/세로 비율 (width / height). 값이 작을수록 세로로 길쭉한 화면.
    public var widthRatio: Double {
        guard logicalHeight > 0 else { return 0 }
        return logicalWidth / logicalHeight
    }

    /// 화면 크기 표시 문자열
    public var screenSizeDescription: String {
        "\(Int(logicalWidth))×\(Int(logicalHeight)) pt"
    }

    public init(identifier: String, screenWidth: Int, screenHeight: Int, screenScale: Int, hasNotch: Bool) {
        self.identifier = identifier
        self.screenWidth = screenWidth
        self.screenHeight = screenHeight
        self.screenScale = screenScale
        self.hasNotch = hasNotch
    }
}
