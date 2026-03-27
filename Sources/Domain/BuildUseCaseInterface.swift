import Foundation

public protocol BuildUseCaseInterface: Sendable {
    func addBuild(from source: URL) async throws -> URL
    func extractZIP(at source: URL) async throws -> URL
    func listLocalApps() -> [URL]
    func deleteLocalBuild(at path: URL) throws
}
