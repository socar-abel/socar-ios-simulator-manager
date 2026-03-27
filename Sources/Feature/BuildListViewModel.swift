import Foundation
import Domain

@Observable
public final class BuildListViewModel {

    public private(set) var isAdding = false
    public var errorMessage: String?
    public var successMessage: String?

    private let buildUseCase: any BuildUseCaseInterface
    private let simulatorUseCase: any SimulatorUseCaseInterface

    public init(
        buildUseCase: any BuildUseCaseInterface,
        simulatorUseCase: any SimulatorUseCaseInterface
    ) {
        self.buildUseCase = buildUseCase
        self.simulatorUseCase = simulatorUseCase
    }

    // MARK: - Input

    public func localApps() -> [URL] {
        buildUseCase.listLocalApps()
    }

    public func addBuild(from url: URL) async {
        isAdding = true
        errorMessage = nil
        defer { isAdding = false }

        do {
            let appURL = try await buildUseCase.addBuild(from: url)
            successMessage = "\(appURL.lastPathComponent) 추가 완료"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func deleteBuild(at path: URL) {
        do {
            try buildUseCase.deleteLocalBuild(at: path)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    public func installOnDevice(appURL: URL, udid: String) async throws {
        try await simulatorUseCase.installApp(udid: udid, appPath: appURL)
        try? await simulatorUseCase.bringSimulatorToFront()
    }

    public func isAppInstalled(appURL: URL, udid: String) async -> Bool {
        guard let bundleId = bundleIdentifier(from: appURL) else { return false }
        return (try? await simulatorUseCase.isAppInstalled(udid: udid, bundleId: bundleId)) ?? false
    }

    private func bundleIdentifier(from appURL: URL) -> String? {
        let plistURL = appURL.appendingPathComponent("Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let bundleId = plist["CFBundleIdentifier"] as? String else { return nil }
        return bundleId
    }

    public func bootedDevices() async -> [SimulatorDevice] {
        (try? await simulatorUseCase.fetchDevices().filter(\.isBooted)) ?? []
    }

    public func dismissError() { errorMessage = nil }
    public func dismissSuccess() { successMessage = nil }
}
