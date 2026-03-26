import Foundation

public struct BuildInfo: Identifiable, Hashable, Sendable {
    public let id: String
    public let fileName: String
    public let version: String
    public let rcNumber: String
    public let scheme: String
    public let size: String?
    public let createdTime: String?

    public var displaySize: String {
        guard let size, let bytes = Int64(size) else { return "-" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    public init(
        id: String,
        fileName: String,
        version: String,
        rcNumber: String,
        scheme: String,
        size: String?,
        createdTime: String?
    ) {
        self.id = id
        self.fileName = fileName
        self.version = version
        self.rcNumber = rcNumber
        self.scheme = scheme
        self.size = size
        self.createdTime = createdTime
    }

    /// "18.17.0-rc.3+devDebug.zip" 파싱
    public static func parse(fileName: String) -> (version: String, rc: String, scheme: String)? {
        guard let regex = try? NSRegularExpression(
            pattern: #"(\d+\.\d+\.\d+)-(rc\.\d+)\+(\w+)\.zip"#
        ) else { return nil }

        let range = NSRange(fileName.startIndex..., in: fileName)
        guard let match = regex.firstMatch(in: fileName, range: range),
              match.numberOfRanges == 4,
              let versionRange = Range(match.range(at: 1), in: fileName),
              let rcRange = Range(match.range(at: 2), in: fileName),
              let schemeRange = Range(match.range(at: 3), in: fileName) else {
            return nil
        }

        return (
            version: String(fileName[versionRange]),
            rc: String(fileName[rcRange]),
            scheme: String(fileName[schemeRange])
        )
    }
}
