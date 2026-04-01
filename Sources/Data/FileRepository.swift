import Foundation
import Core
import Domain

public final class FileRepository: FileRepositoryInterface {

    public let buildsDirectory: URL

    public init() {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("SOCARSimulatorManager")
        buildsDirectory = appSupport
            .appendingPathComponent("SOCARSimulatorManager")
            .appendingPathComponent("Builds")
        ensureBuildsDirectoryExists()
    }

    private func ensureBuildsDirectoryExists() {
        if !FileManager.default.fileExists(atPath: buildsDirectory.path) {
            try? FileManager.default.createDirectory(at: buildsDirectory, withIntermediateDirectories: true)
        }
    }

    public func extractZIP(at source: URL) async throws -> URL {
        ensureBuildsDirectoryExists()
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

        defer {
            try? stderrPipe.fileHandleForReading.close()
            try? stderrPipe.fileHandleForWriting.close()
        }

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
        ensureBuildsDirectoryExists()
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
        // parentDir이 buildsDirectory 자체이면 .app만 삭제 (전체 삭제 방지)
        // parentDir이 buildsDirectory 하위 폴더이면 폴더째 삭제
        if parentDir.path == buildsDirectory.path {
            // Builds/SOCAR.app → .app만 삭제
            try FileManager.default.removeItem(at: path)
        } else if parentDir.path.hasPrefix(buildsDirectory.path) {
            // Builds/extracted/SOCAR.app → extracted 폴더째 삭제
            try FileManager.default.removeItem(at: parentDir)
        }
    }

    public func copyToBuildDirectory(from source: URL) throws -> URL {
        ensureBuildsDirectoryExists()
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
