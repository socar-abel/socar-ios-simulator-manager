import Foundation

public protocol BuildUseCaseInterface: Sendable {
    func listRemoteBuilds(folderId: String) async throws -> [BuildInfo]
    func downloadBuild(fileId: String, fileName: String, progress: @escaping @Sendable (Double) -> Void) async throws -> URL
    func extractZIP(at source: URL) async throws -> URL
    func listLocalApps() -> [URL]
    func deleteLocalBuild(at path: URL) throws
}
