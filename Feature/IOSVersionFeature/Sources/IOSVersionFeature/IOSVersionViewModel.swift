import Foundation
import SimulatorDomainInterface

@Observable
public final class IOSVersionViewModel {

    public private(set) var installedIOSVersions: [InstalledIOSVersion] = []
    public private(set) var diskUsage: DiskUsage?
    public private(set) var isLoading = false
    public private(set) var isDownloading = false
    public private(set) var isDeleting = false
    public var errorMessage: String?
    public var successMessage: String?

    private let useCase: any SimulatorUseCaseInterface

    public init(useCase: any SimulatorUseCaseInterface) {
        self.useCase = useCase
    }

    // MARK: - Input

    public func onAppear() async {
        await refreshAll()
    }

    public func refreshAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let runtimes = useCase.fetchInstalledIOSVersions()
            async let disk = useCase.fetchDiskUsage()
            installedIOSVersions = try await runtimes
            diskUsage = try await disk
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteIOSVersion(_ runtime: InstalledIOSVersion) async {
        guard runtime.isDeletable else {
            errorMessage = "이 iOS 버전은 삭제할 수 없습니다."
            return
        }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await useCase.deleteIOSVersion(identifier: runtime.identifier)
            successMessage = "\(runtime.displayName) iOS 버전이 삭제되었습니다."
            await refreshAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func downloadLatestIOSVersion() async {
        isDownloading = true
        errorMessage = nil
        defer { isDownloading = false }

        do {
            try await useCase.downloadIOSVersion(platform: "iOS")
            successMessage = "최신 iOS 버전 다운로드가 완료되었습니다."
            await refreshAll()
        } catch {
            errorMessage = "iOS 버전 다운로드 실패: \(error.localizedDescription)"
        }
    }

    public func cleanupUnavailableDevices() async {
        errorMessage = nil
        do {
            try await useCase.deleteAllUnavailableDevices()
            successMessage = "사용 불가능한 디바이스가 정리되었습니다."
            await refreshAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func dismissError() { errorMessage = nil }
    public func dismissSuccess() { successMessage = nil }
}
