import Foundation

/// simctl runtime list에서 가져오는 설치된 런타임 상세 정보
public struct InstalledIOSVersion: Identifiable, Hashable, Sendable {
    public let identifier: String
    public let runtimeIdentifier: String
    public let version: String
    public let sizeBytes: Int64
    public let isDeletable: Bool
    public let state: String
    public let lastUsedAt: String?

    public var id: String { identifier }

    public var displayName: String {
        let stripped = runtimeIdentifier.replacingOccurrences(
            of: "com.apple.CoreSimulator.SimRuntime.",
            with: ""
        )
        let parts = stripped.split(separator: "-")
        guard parts.count >= 2 else { return "iOS \(version)" }
        let platform = parts[0]
        let ver = parts.dropFirst().joined(separator: ".")
        return "\(platform) \(ver)"
    }

    public var displaySize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: sizeBytes)
    }

    public var isReady: Bool { state == "Ready" }

    /// 사용자에게 보여줄 상태 문구
    public var displayState: String {
        switch state {
        case "Ready": return "Ready"
        case "Unusable": return "등록 중... (잠시 기다려주세요)"
        case "Deleting": return "삭제 중..."
        default: return state
        }
    }

    public init(
        identifier: String,
        runtimeIdentifier: String,
        version: String,
        sizeBytes: Int64,
        isDeletable: Bool,
        state: String,
        lastUsedAt: String?
    ) {
        self.identifier = identifier
        self.runtimeIdentifier = runtimeIdentifier
        self.version = version
        self.sizeBytes = sizeBytes
        self.isDeletable = isDeletable
        self.state = state
        self.lastUsedAt = lastUsedAt
    }
}
