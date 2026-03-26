import Foundation

public struct DiskUsage: Sendable {
    public let iosVersionsBytes: Int64
    public let devicesBytes: Int64
    public let buildsBytes: Int64

    public var totalBytes: Int64 { iosVersionsBytes + devicesBytes + buildsBytes }

    public var iosVersionsDisplay: String { format(iosVersionsBytes) }
    public var devicesDisplay: String { format(devicesBytes) }
    public var buildsDisplay: String { format(buildsBytes) }
    public var totalDisplay: String { format(totalBytes) }

    public init(iosVersionsBytes: Int64, devicesBytes: Int64, buildsBytes: Int64) {
        self.iosVersionsBytes = iosVersionsBytes
        self.devicesBytes = devicesBytes
        self.buildsBytes = buildsBytes
    }

    private func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}
