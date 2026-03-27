import Foundation
import Domain

@Observable
public final class IOSVersionViewModel {

    public private(set) var installedIOSVersions: [InstalledIOSVersion] = []
    public private(set) var downloadableIOSVersions: [DownloadableIOSVersion] = []
    public private(set) var diskUsage: DiskUsage?
    public private(set) var isLoading = false
    public private(set) var isLoadingDownloadable = false
    public private(set) var isDownloading = false
    public private(set) var downloadingVersionName: String?
    public private(set) var isDeleting = false
    public private(set) var deletingVersionId: String?
    public private(set) var isCleaning = false
    public var errorMessage: String?
    public var successMessage: String?

    private let useCase: any SimulatorUseCaseInterface

    public init(useCase: any SimulatorUseCaseInterface) {
        self.useCase = useCase
    }

    // MARK: - Input

    public func onAppear() async {
        await refreshAll()
        await loadDownloadableVersions()
    }

    public func refreshAll() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let versions = useCase.fetchInstalledIOSVersions()
            async let disk = useCase.fetchDiskUsage()
            installedIOSVersions = try await versions
            diskUsage = try await disk
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func loadDownloadableVersions() async {
        isLoadingDownloadable = true
        defer { isLoadingDownloadable = false }

        do {
            downloadableIOSVersions = try await useCase.fetchDownloadableIOSVersions()
        } catch {
            // 네트워크 실패 시 조용히 무시 (설치된 목록은 표시)
        }
    }

    public func deleteIOSVersion(_ version: InstalledIOSVersion) async {
        guard version.isDeletable else {
            errorMessage = "이 iOS 버전은 삭제할 수 없습니다."
            return
        }
        isDeleting = true
        deletingVersionId = version.identifier
        errorMessage = nil
        defer {
            isDeleting = false
            deletingVersionId = nil
        }

        do {
            try await useCase.deleteIOSVersion(identifier: version.identifier)
            successMessage = "\(version.displayName)이(가) 삭제되었습니다."
            // 파일시스템 정리 대기 후 디스크 사용량 갱신
            try? await Task.sleep(for: .seconds(1))
            await refreshAll()
            await loadDownloadableVersions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func downloadIOSVersion(_ version: DownloadableIOSVersion) async {
        isDownloading = true
        downloadingVersionName = version.shortName
        errorMessage = nil
        defer {
            isDownloading = false
            downloadingVersionName = nil
        }

        do {
            try await useCase.downloadIOSVersion(platform: "iOS", buildVersion: version.buildVersion)
            successMessage = "\(version.shortName) 다운로드가 완료되었습니다."
            await refreshAll()
            await loadDownloadableVersions()
        } catch {
            errorMessage = "\(version.shortName) 다운로드 실패: \(error.localizedDescription)"
        }
    }

    public func cleanupUnavailableDevices() async {
        isCleaning = true
        errorMessage = nil
        defer { isCleaning = false }

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
