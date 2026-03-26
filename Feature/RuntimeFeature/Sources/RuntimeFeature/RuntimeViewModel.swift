import Foundation
import SimulatorDomainInterface

@Observable
public final class RuntimeViewModel {

    public private(set) var installedRuntimes: [InstalledRuntime] = []
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
            async let runtimes = useCase.fetchInstalledRuntimes()
            async let disk = useCase.fetchDiskUsage()
            installedRuntimes = try await runtimes
            diskUsage = try await disk
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteRuntime(_ runtime: InstalledRuntime) async {
        guard runtime.isDeletable else {
            errorMessage = "이 런타임은 삭제할 수 없습니다."
            return
        }
        isDeleting = true
        errorMessage = nil
        defer { isDeleting = false }

        do {
            try await useCase.deleteRuntime(identifier: runtime.identifier)
            successMessage = "\(runtime.displayName) 런타임이 삭제되었습니다."
            await refreshAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func downloadiOSRuntime() async {
        isDownloading = true
        errorMessage = nil
        defer { isDownloading = false }

        do {
            try await useCase.downloadRuntime(platform: "iOS")
            successMessage = "iOS 런타임 다운로드가 완료되었습니다."
            await refreshAll()
        } catch {
            errorMessage = "런타임 다운로드 실패: \(error.localizedDescription)"
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
