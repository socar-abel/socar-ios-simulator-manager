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
    public private(set) var downloadProgress: DownloadProgress?
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
        await silentRefresh()
    }

    /// 로딩 표시 없이 데이터만 갱신 (폴링용)
    private func silentRefresh() async {
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
            // 실제 삭제 완료까지 폴링 (최대 30초)
            for _ in 0..<15 {
                try? await Task.sleep(for: .seconds(2))
                await silentRefresh()
                if !installedIOSVersions.contains(where: { $0.identifier == version.identifier }) {
                    break
                }
            }
            successMessage = "\(version.displayName)이(가) 삭제되었습니다."
            await loadDownloadableVersions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func downloadIOSVersion(_ version: DownloadableIOSVersion) async {
        isDownloading = true
        downloadingVersionName = version.shortName
        downloadProgress = DownloadProgress(status: .preparing)
        errorMessage = nil
        defer {
            isDownloading = false
            downloadingVersionName = nil
            downloadProgress = nil
        }

        do {
            try await useCase.downloadIOSVersionWithProgress(
                platform: "iOS",
                buildVersion: version.buildVersion
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.downloadProgress = progress
                }
            }
            downloadProgress = DownloadProgress(status: .installing)
            // 설치 등록 완료까지 폴링 (최대 30초) — 버전명으로 확인
            let targetName = version.shortName
            for _ in 0..<15 {
                await silentRefresh()
                if installedIOSVersions.contains(where: { $0.displayName == targetName }) {
                    break
                }
                try? await Task.sleep(for: .seconds(2))
            }
            successMessage = "\(version.shortName) 다운로드가 완료되었습니다."
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
