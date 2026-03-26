import Foundation

public struct RemoteFile: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let size: String?
    public let createdTime: String?

    public init(id: String, name: String, size: String?, createdTime: String?) {
        self.id = id
        self.name = name
        self.size = size
        self.createdTime = createdTime
    }
}

public protocol BuildRepositoryInterface: Sendable {
    /// Google Drive에서 파일 목록 조회
    func listFiles(folderId: String) async throws -> [RemoteFile]
    /// Google Drive에서 파일 다운로드
    func downloadFile(fileId: String, to destination: URL, progress: @escaping @Sendable (Double) -> Void) async throws -> URL
}

public protocol FileRepositoryInterface {
    var buildsDirectory: URL { get }
    func extractZIP(at source: URL) async throws -> URL
    func listLocalApps() -> [URL]
    func deleteLocalBuild(at path: URL) throws
}

public protocol KeychainRepositoryInterface {
    func storeServiceAccountJSON(_ data: Data) throws
    func retrieveServiceAccountJSON() throws -> Data?
    func deleteServiceAccountJSON() throws
}
