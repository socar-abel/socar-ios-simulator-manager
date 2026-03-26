import Foundation
import Security
import BuildDomainInterface

/// Google Drive API를 통한 BuildRepository 구현
public actor GoogleDriveRepository: BuildRepositoryInterface {

    private struct TokenResponse: Codable {
        let access_token: String
        let expires_in: Int
    }

    private struct FileListResponse: Codable {
        struct DriveFile: Codable {
            let id: String
            let name: String
            let size: String?
            let createdTime: String?
        }
        let files: [DriveFile]?
    }

    private struct ServiceAccountKey: Codable {
        let client_email: String
        let private_key: String
        let token_uri: String
    }

    private var accessToken: String?
    private var tokenExpiresAt: Date?
    private let serviceAccountKey: ServiceAccountKey

    public init(serviceAccountJSON: Data) throws {
        self.serviceAccountKey = try JSONDecoder().decode(
            ServiceAccountKey.self,
            from: serviceAccountJSON
        )
    }

    public func listFiles(folderId: String) async throws -> [RemoteFile] {
        let token = try await getAccessToken()

        let query = "'\(folderId)' in parents and trashed = false"
        var components = URLComponents(string: "https://www.googleapis.com/drive/v3/files")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "fields", value: "files(id,name,size,createdTime)"),
            URLQueryItem(name: "orderBy", value: "createdTime desc"),
            URLQueryItem(name: "pageSize", value: "50"),
        ]

        var request = URLRequest(url: components.url!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GoogleDriveError.apiError(String(data: data, encoding: .utf8) ?? "Unknown")
        }

        let result = try JSONDecoder().decode(FileListResponse.self, from: data)
        return (result.files ?? []).map {
            RemoteFile(id: $0.id, name: $0.name, size: $0.size, createdTime: $0.createdTime)
        }
    }

    public func downloadFile(
        fileId: String,
        to destination: URL,
        progress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let token = try await getAccessToken()

        let url = URL(string: "https://www.googleapis.com/drive/v3/files/\(fileId)?alt=media")!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (bytes, response) = try await URLSession.shared.bytes(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw GoogleDriveError.downloadFailed
        }

        let totalSize = http.expectedContentLength
        var downloadedSize: Int64 = 0
        var buffer = Data()

        for try await byte in bytes {
            buffer.append(byte)
            downloadedSize += 1
            if downloadedSize % 65536 == 0, totalSize > 0 {
                progress(Double(downloadedSize) / Double(totalSize))
            }
        }

        try buffer.write(to: destination)
        progress(1.0)
        return destination
    }

    // MARK: - JWT

    private func getAccessToken() async throws -> String {
        if let token = accessToken, let expiry = tokenExpiresAt, expiry > Date() {
            return token
        }

        let jwt = try createJWT()
        var request = URLRequest(url: URL(string: serviceAccountKey.token_uri)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=\(jwt)"
            .data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)

        accessToken = tokenResponse.access_token
        tokenExpiresAt = Date().addingTimeInterval(TimeInterval(tokenResponse.expires_in - 60))
        return tokenResponse.access_token
    }

    private func createJWT() throws -> String {
        let now = Date()
        let header = ["alg": "RS256", "typ": "JWT"]
        let claims: [String: Any] = [
            "iss": serviceAccountKey.client_email,
            "scope": "https://www.googleapis.com/auth/drive.readonly",
            "aud": serviceAccountKey.token_uri,
            "iat": Int(now.timeIntervalSince1970),
            "exp": Int(now.timeIntervalSince1970) + 3600,
        ]

        let headerData = try JSONSerialization.data(withJSONObject: header)
        let claimsData = try JSONSerialization.data(withJSONObject: claims)
        let headerB64 = headerData.base64URLEncoded
        let claimsB64 = claimsData.base64URLEncoded

        let signingInput = "\(headerB64).\(claimsB64)"
        guard let signingData = signingInput.data(using: .utf8) else {
            throw GoogleDriveError.jwtCreationFailed
        }

        let signature = try signWithRSA(data: signingData)
        return "\(headerB64).\(claimsB64).\(signature.base64URLEncoded)"
    }

    private func signWithRSA(data: Data) throws -> Data {
        let stripped = serviceAccountKey.private_key
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")

        guard let keyData = Data(base64Encoded: stripped) else {
            throw GoogleDriveError.invalidPrivateKey
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
        ]

        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(keyData as CFData, attributes as CFDictionary, &error),
              let signature = SecKeyCreateSignature(key, .rsaSignatureMessagePKCS1v15SHA256, data as CFData, &error) else {
            throw GoogleDriveError.signingFailed
        }
        return signature as Data
    }
}

private extension Data {
    var base64URLEncoded: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

public enum GoogleDriveError: LocalizedError {
    case invalidPrivateKey, jwtCreationFailed, signingFailed
    case apiError(String), downloadFailed

    public var errorDescription: String? {
        switch self {
        case .invalidPrivateKey: return "서비스 계정 키가 올바르지 않습니다."
        case .jwtCreationFailed: return "JWT 토큰 생성에 실패했습니다."
        case .signingFailed: return "서명 생성에 실패했습니다."
        case .apiError(let msg): return "Google Drive API 오류: \(msg)"
        case .downloadFailed: return "파일 다운로드에 실패했습니다."
        }
    }
}
