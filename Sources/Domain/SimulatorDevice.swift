import Foundation

public struct SimulatorDevice: Identifiable, Hashable, Sendable {
    public let udid: String
    public let name: String
    public let state: String
    public let isAvailable: Bool
    public let deviceTypeIdentifier: String?
    public var runtimeIdentifier: String?

    public var id: String { udid }
    public var isBooted: Bool { state == "Booted" }
    public var isShutdown: Bool { state == "Shutdown" }

    public var stateDisplayName: String {
        switch state {
        case "Booted": return "실행중"
        case "Shutdown": return "종료됨"
        case "Creating": return "생성중"
        default: return state
        }
    }

    public var runtimeDisplayName: String? {
        guard let runtime = runtimeIdentifier else { return nil }
        let stripped = runtime.replacingOccurrences(
            of: "com.apple.CoreSimulator.SimRuntime.",
            with: ""
        )
        let parts = stripped.split(separator: "-")
        guard parts.count >= 2 else { return stripped }
        let platform = parts[0]
        let version = parts.dropFirst().joined(separator: ".")
        return "\(platform) \(version)"
    }

    public init(
        udid: String,
        name: String,
        state: String,
        isAvailable: Bool,
        deviceTypeIdentifier: String?,
        runtimeIdentifier: String?
    ) {
        self.udid = udid
        self.name = name
        self.state = state
        self.isAvailable = isAvailable
        self.deviceTypeIdentifier = deviceTypeIdentifier
        self.runtimeIdentifier = runtimeIdentifier
    }
}
