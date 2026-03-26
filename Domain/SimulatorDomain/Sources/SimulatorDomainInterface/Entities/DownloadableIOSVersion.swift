import Foundation

public struct DownloadableIOSVersion: Identifiable, Hashable, Sendable {
    public let name: String
    public let version: String
    public let fileSize: Int64
    public let source: String
    public let contentType: String

    public var id: String { "\(name)-\(version)-\(contentType)" }

    public var displaySize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }

    /// "iOS 18.3 Simulator Runtime" → "iOS 18.3"
    public var shortName: String {
        name.replacingOccurrences(of: " Simulator Runtime", with: "")
            .replacingOccurrences(of: " Simulator", with: "")
    }

    public var isBeta: Bool {
        name.lowercased().contains("beta")
    }

    public init(name: String, version: String, fileSize: Int64, source: String, contentType: String) {
        self.name = name
        self.version = version
        self.fileSize = fileSize
        self.source = source
        self.contentType = contentType
    }
}
