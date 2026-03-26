import Foundation
import BuildDomainInterface

public protocol BuildUseCaseDependency {
    var buildRepository: any BuildRepositoryInterface { get }
    var fileRepository: any FileRepositoryInterface { get }
}

public final class BuildUseCase<Dependency: BuildUseCaseDependency>: BuildUseCaseInterface {

    private let dependency: Dependency

    public init(dependency: Dependency) {
        self.dependency = dependency
    }

    public func listRemoteBuilds(folderId: String) async throws -> [BuildInfo] {
        let files = try await dependency.buildRepository.listFiles(folderId: folderId)
        return files.compactMap { file in
            guard let parsed = BuildInfo.parse(fileName: file.name) else { return nil }
            return BuildInfo(
                id: file.id,
                fileName: file.name,
                version: parsed.version,
                rcNumber: parsed.rc,
                scheme: parsed.scheme,
                size: file.size,
                createdTime: file.createdTime
            )
        }
    }

    public func downloadBuild(
        fileId: String,
        fileName: String,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let destination = dependency.fileRepository.buildsDirectory
            .appendingPathComponent(fileName)
        return try await dependency.buildRepository.downloadFile(
            fileId: fileId,
            to: destination,
            progress: progress
        )
    }

    public func extractZIP(at source: URL) async throws -> URL {
        try await dependency.fileRepository.extractZIP(at: source)
    }

    public func listLocalApps() -> [URL] {
        dependency.fileRepository.listLocalApps()
    }

    public func deleteLocalBuild(at path: URL) throws {
        try dependency.fileRepository.deleteLocalBuild(at: path)
    }
}
