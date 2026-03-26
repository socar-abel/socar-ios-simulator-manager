import Foundation
import Security
import BuildDomainInterface

public final class KeychainRepository: KeychainRepositoryInterface {

    private let service = "com.socar.simulator-manager"
    private let account = "gcp-service-account"

    public init() {}

    public func storeServiceAccountJSON(_ data: Data) throws {
        try? deleteServiceAccountJSON()

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }

    public func retrieveServiceAccountJSON() throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw KeychainError.retrieveFailed(status)
        }
    }

    public func deleteServiceAccountJSON() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

public enum KeychainError: LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .storeFailed(let s): return "키체인 저장 실패 (코드: \(s))"
        case .retrieveFailed(let s): return "키체인 조회 실패 (코드: \(s))"
        case .deleteFailed(let s): return "키체인 삭제 실패 (코드: \(s))"
        }
    }
}
