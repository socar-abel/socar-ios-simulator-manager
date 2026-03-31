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
    public private(set) var downloadableLoadFailed = false
    private var downloadTask: Task<Void, Never>?
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
            downloadableLoadFailed = false
        } catch {
            downloadableLoadFailed = true
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
            // 실제 삭제 완료까지 폴링 (최대 60초)
            var deleted = false
            for _ in 0..<30 {
                try? await Task.sleep(for: .seconds(2))
                await silentRefresh()
                if !installedIOSVersions.contains(where: { $0.identifier == version.identifier }) {
                    deleted = true
                    break
                }
            }
            // 로딩 해제 + 스낵바를 먼저 표시
            isDeleting = false
            deletingVersionId = nil
            if deleted {
                successMessage = "\(version.displayName)이(가) 삭제되었습니다."
            } else {
                successMessage = "\(version.displayName) 삭제가 진행 중입니다. 잠시 후 새로고침해주세요."
            }
            // 다운로드 가능 목록 갱신은 백그라운드로 (네트워크 호출)
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

        downloadTask = Task {
            defer {
                isDownloading = false
                downloadingVersionName = nil
                downloadProgress = nil
                downloadTask = nil
            }

            do {
                try await useCase.downloadIOSVersionWithProgress(
                    platform: "iOS",
                    buildVersion: version.buildVersion
                ) { [weak self] progress in
                    Task { @MainActor in
                        guard let self else { return }
                        // 상태 변경 또는 1% 이상 차이일 때만 UI 갱신
                        if let current = self.downloadProgress {
                            let statusChanged = {
                                switch (current.status, progress.status) {
                                case (.preparing, .preparing), (.downloading, .downloading), (.installing, .installing):
                                    return false
                                default:
                                    return true
                                }
                            }()
                            if !statusChanged && abs(progress.percent - current.percent) < 1.0 {
                                return
                            }
                        }
                        self.downloadProgress = progress
                    }
                }

                guard !Task.isCancelled else {
                    successMessage = "\(version.shortName) 다운로드가 취소되었습니다."
                    return
                }

                // xcodebuild 종료 = 다운로드+설치 완료
                // 즉시 로딩 해제 + 스낵바
                isDownloading = false
                downloadingVersionName = nil
                downloadProgress = nil
                successMessage = "\(version.shortName) 다운로드가 완료되었습니다."
                // 백그라운드에서 목록 갱신
                await silentRefresh()
                await loadDownloadableVersions()
            } catch {
                if !Task.isCancelled {
                    errorMessage = "\(version.shortName) 다운로드 실패: \(error.localizedDescription)"
                }
            }
        }
    }

    public func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        isDownloading = false
        downloadingVersionName = nil
        downloadProgress = nil
        successMessage = "다운로드가 취소되었습니다."
    }

    public func cleanupUnavailableDevices() async {
        isCleaning = true
        errorMessage = nil

        do {
            try await useCase.deleteAllUnavailableDevices()
            isCleaning = false
            successMessage = "사용 불가능한 디바이스가 정리되었습니다."
            await refreshAll()
        } catch {
            isCleaning = false
            errorMessage = error.localizedDescription
        }
    }

    public func dismissError() { errorMessage = nil }
    public func dismissSuccess() { successMessage = nil }
}
