import Foundation

public protocol FileRepositoryInterface {
    var buildsDirectory: URL { get }
    func extractZIP(at source: URL) async throws -> URL
    func listLocalApps() -> [URL]
    func deleteLocalBuild(at path: URL) throws
    func copyToBuildDirectory(from source: URL) throws -> URL
}
