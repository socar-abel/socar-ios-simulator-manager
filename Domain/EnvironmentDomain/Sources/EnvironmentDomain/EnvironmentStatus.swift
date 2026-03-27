import Foundation

public struct EnvironmentStatus: Sendable {
    public let xcodeInstalled: Bool
    public let xcodePath: String?
    public let xcodeVersion: String?
    public let commandLineToolsInstalled: Bool
    public let availableRuntimes: [String]

    /// Xcode와 CLT가 있으면 앱 사용 가능 (런타임은 앱 내에서 다운로드 가능)
    public var isReady: Bool {
        xcodeInstalled && commandLineToolsInstalled
    }

    /// 앱 진입을 막는 심각한 문제
    public var issues: [EnvironmentIssue] {
        var result: [EnvironmentIssue] = []
        if !xcodeInstalled { result.append(.xcodeNotInstalled) }
        else if !commandLineToolsInstalled { result.append(.commandLineToolsNotInstalled) }
        return result
    }

    /// 앱은 사용 가능하지만 알려줘야 할 경고
    public var warnings: [EnvironmentIssue] {
        guard isReady else { return [] }
        var result: [EnvironmentIssue] = []
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
        case .noRuntimesAvailable: return "설치된 iOS 버전이 없습니다"
        }
    }

    public var description: String {
        switch self {
        case .xcodeNotInstalled: return "App Store에서 Xcode를 설치한 후, 한 번 실행하여 라이선스 동의와 추가 컴포넌트 설치를 완료해주세요."
        case .commandLineToolsNotInstalled: return "Xcode를 한 번 실행하여 초기 설정을 완료하거나, 터미널에서 'xcode-select --install'을 실행해주세요."
        case .noRuntimesAvailable: return "iOS 버전 탭에서 원하는 버전을 다운로드할 수 있습니다."
        }
    }
}
