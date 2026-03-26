import Foundation

public struct DiskUsage: Sendable {
    public let runtimesBytes: Int64
    public let devicesBytes: Int64
    public let buildsBytes: Int64

    public var totalBytes: Int64 { runtimesBytes + devicesBytes + buildsBytes }

    public var runtimesDisplay: String { format(runtimesBytes) }
    public var devicesDisplay: String { format(devicesBytes) }
    public var buildsDisplay: String { format(buildsBytes) }
    public var totalDisplay: String { format(totalBytes) }

    public init(runtimesBytes: Int64, devicesBytes: Int64, buildsBytes: Int64) {
        self.runtimesBytes = runtimesBytes
        self.devicesBytes = devicesBytes
        self.buildsBytes = buildsBytes
    }

    private func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
