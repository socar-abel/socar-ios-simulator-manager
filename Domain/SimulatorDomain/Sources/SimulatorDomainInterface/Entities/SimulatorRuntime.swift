import Foundation

public struct SimulatorRuntime: Identifiable, Hashable, Sendable {
    public let identifier: String
    public let name: String
    public let version: String
    public let isAvailable: Bool

    public var id: String { identifier }
    public var isIOS: Bool { identifier.contains("iOS") }

    public init(identifier: String, name: String, version: String, isAvailable: Bool) {
        self.identifier = identifier
        self.name = name
        self.version = version
        self.isAvailable = isAvailable
    }
}
