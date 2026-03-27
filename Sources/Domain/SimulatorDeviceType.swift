import Foundation

public struct SimulatorDeviceType: Identifiable, Hashable, Sendable {
    public let identifier: String
    public let name: String
    public let productFamily: String?

    public var id: String { identifier }
    public var isIPhone: Bool { productFamily == "iPhone" || name.contains("iPhone") }
    public var isIPad: Bool { productFamily == "iPad" || name.contains("iPad") }

    public init(identifier: String, name: String, productFamily: String?) {
        self.identifier = identifier
        self.name = name
        self.productFamily = productFamily
    }
}
