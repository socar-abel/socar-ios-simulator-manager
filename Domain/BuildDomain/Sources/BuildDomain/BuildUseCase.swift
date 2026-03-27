import Foundation
import BuildDomainInterface

public protocol BuildUseCaseDependency {
    var fileRepository: any FileRepositoryInterface { get }
}

public final class BuildUseCase<Dependency: BuildUseCaseDependency>: BuildUseCaseInterface {

    private let dependency: Dependency

    public init(dependency: Dependency) {
        self.dependency = dependency
    }

    public func addBuild(from source: URL) async throws -> URL {
        let ext = source.pathExtension.lowercased()
        if ext == "zip" {
            let copied = try dependency.fileRepository.copyToBuildDirectory(from: source)
            let appURL = try await dependency.fileRepository.extractZIP(at: copied)
            try? FileManager.default.removeItem(at: copied)
            return appURL
        } else {
            return try dependency.fileRepository.copyToBuildDirectory(from: source)
        }
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
