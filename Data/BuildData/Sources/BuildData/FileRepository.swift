import Foundation
import BuildDomainInterface

public final class FileRepository: FileRepositoryInterface {

    public let buildsDirectory: URL

    public init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        buildsDirectory = appSupport
            .appendingPathComponent("SOCARSimulatorManager")
            .appendingPathComponent("Builds")
        try? FileManager.default.createDirectory(at: buildsDirectory, withIntermediateDirectories: true)
    }

    public func extractZIP(at source: URL) async throws -> URL {
        let extractDir = buildsDirectory.appendingPathComponent(
            source.deletingPathExtension().lastPathComponent
        )

        if FileManager.default.fileExists(atPath: extractDir.path) {
            try FileManager.default.removeItem(at: extractDir)
        }
        try FileManager.default.createDirectory(at: extractDir, withIntermediateDirectories: true)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/unzip")
        process.arguments = ["-o", source.path(percentEncoded: false), "-d", extractDir.path(percentEncoded: false)]
        process.standardOutput = FileHandle.nullDevice
        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            throw FileRepositoryError.extractionFailed(stderr)
        }

        guard let appURL = findAppBundle(in: extractDir) else {
            throw FileRepositoryError.appNotFoundInZip
        }
        return appURL
    }

    public func listLocalApps() -> [URL] {
        guard let enumerator = FileManager.default.enumerator(
            at: buildsDirectory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }

        var apps: [URL] = []
        for case let url as URL in enumerator {
            if url.pathExtension == "app" {
                apps.append(url)
                enumerator.skipDescendants()
            }
        }
        return apps
    }

    public func deleteLocalBuild(at path: URL) throws {
        let parentDir = path.deletingLastPathComponent()
        if parentDir.path.hasPrefix(buildsDirectory.path) {
            try FileManager.default.removeItem(at: parentDir)
        }
    }

    public func copyToBuildDirectory(from source: URL) throws -> URL {
        let destination = buildsDirectory.appendingPathComponent(source.lastPathComponent)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        _ = source.startAccessingSecurityScopedResource()
        defer { source.stopAccessingSecurityScopedResource() }
        try FileManager.default.copyItem(at: source, to: destination)
        return destination
    }

    private func findAppBundle(in directory: URL) -> URL? {
        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else { return nil }

        for case let url as URL in enumerator {
            if url.pathExtension == "app" { return url }
        }
        return nil
    }
}

public enum FileRepositoryError: LocalizedError {
    case extractionFailed(String)
    case appNotFoundInZip

    public var errorDescription: String? {
        switch self {
        case .extractionFailed(let reason): return "ZIP 추출 실패: \(reason)"
        case .appNotFoundInZip: return "ZIP 파일 안에 .app 파일을 찾을 수 없습니다."
        }
    }
}
