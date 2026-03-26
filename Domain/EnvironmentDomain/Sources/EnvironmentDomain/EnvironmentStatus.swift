import Foundation

public struct EnvironmentStatus: Sendable {
    public let xcodeInstalled: Bool
    public let xcodePath: String?
    public let xcodeVersion: String?
    public let commandLineToolsInstalled: Bool
    public let availableRuntimes: [String]

    public var isReady: Bool {
        xcodeInstalled && !availableRuntimes.isEmpty
    }

    public var issues: [EnvironmentIssue] {
        var result: [EnvironmentIssue] = []
        if !xcodeInstalled { result.append(.xcodeNotInstalled) }
        if !commandLineToolsInstalled { result.append(.commandLineToolsNotInstalled) }
        if availableRuntimes.isEmpty { result.append(.noRuntimesAvailable) }
        return result
    }

    public init(
        xcodeInstalled: Bool,
        xcodePath: String?,
        xcodeVersion: String?,
        commandLineToolsInstalled: Bool,
        availableRuntimes: [String]
    ) {
        self.xcodeInstalled = xcodeInstalled
        self.xcodePath = xcodePath
        self.xcodeVersion = xcodeVersion
        self.commandLineToolsInstalled = commandLineToolsInstalled
        self.availableRuntimes = availableRuntimes
    }
}

public enum EnvironmentIssue: Sendable {
    case xcodeNotInstalled
    case commandLineToolsNotInstalled
    case noRuntimesAvailable

    public var title: String {
        switch self {
        case .xcodeNotInstalled: return "Xcode가 설치되어 있지 않습니다"
        case .commandLineToolsNotInstalled: return "Command Line Tools가 설치되어 있지 않습니다"
        case .noRuntimesAvailable: return "iOS 시뮬레이터 런타임이 없습니다"
        }
    }

    public var description: String {
        switch self {
        case .xcodeNotInstalled: return "App Store에서 Xcode를 설치하거나, IT팀에 설치를 요청해주세요."
        case .commandLineToolsNotInstalled: return "터미널에서 'xcode-select --install'을 실행해주세요."
        case .noRuntimesAvailable: return "Xcode를 열고 Settings > Platforms에서 iOS 런타임을 다운로드해주세요."
        }
    }
}
