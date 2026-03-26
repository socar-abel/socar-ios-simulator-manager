import Foundation
import BuildDomainInterface
import EnvironmentDomain

@Observable
public final class SettingsViewModel {

    public private(set) var hasServiceAccountKey = false
    public private(set) var statusMessage: String?
    public private(set) var isError = false
    public private(set) var environmentStatus: EnvironmentStatus?

    public var folderId: String

    private let keychainRepository: any KeychainRepositoryInterface
    private let environmentCheckUseCase: EnvironmentCheckUseCase

    public init(
        keychainRepository: any KeychainRepositoryInterface,
        environmentCheckUseCase: EnvironmentCheckUseCase,
        defaultFolderId: String
    ) {
        self.keychainRepository = keychainRepository
        self.environmentCheckUseCase = environmentCheckUseCase
        self.folderId = defaultFolderId
        checkExistingKey()
    }

    public func onAppear() async {
        environmentStatus = await environmentCheckUseCase.check()
    }

    public func importServiceAccountKey(from url: URL) {
        do {
            let data = try Data(contentsOf: url)
            _ = try JSONSerialization.jsonObject(with: data)
            try keychainRepository.storeServiceAccountJSON(data)
            hasServiceAccountKey = true
            statusMessage = "서비스 계정 키가 등록되었습니다."
            isError = false
        } catch {
            statusMessage = "올바른 JSON 파일이 아닙니다: \(error.localizedDescription)"
            isError = true
        }
    }

    public func removeServiceAccountKey() {
        try? keychainRepository.deleteServiceAccountJSON()
        hasServiceAccountKey = false
        statusMessage = "서비스 계정 키가 삭제되었습니다."
        isError = false
    }

    private func checkExistingKey() {
        hasServiceAccountKey = (try? keychainRepository.retrieveServiceAccountJSON()) != nil
    }
}
