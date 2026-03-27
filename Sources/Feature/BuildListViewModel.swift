import Foundation
import AppKit
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

    public func appInfo(from appURL: URL) -> AppBundleInfo {
        AppBundleInfo(appURL: appURL)
    }

    private func bundleIdentifier(from appURL: URL) -> String? {
        appInfo(from: appURL).bundleId
    }

    public func bootedDevices() async -> [SimulatorDevice] {
        (try? await simulatorUseCase.fetchDevices().filter(\.isBooted)) ?? []
    }

    public func dismissError() { errorMessage = nil }
    public func dismissSuccess() { successMessage = nil }
}

// MARK: - App Bundle Info

public struct AppBundleInfo {
    public let appURL: URL

    private var plist: [String: Any]? {
        let plistURL = appURL.appendingPathComponent("Info.plist")
        guard let data = try? Data(contentsOf: plistURL),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return nil }
        return dict
    }

    public var bundleId: String? {
        plist?["CFBundleIdentifier"] as? String
    }

    public var version: String? {
        plist?["CFBundleShortVersionString"] as? String
    }

    public var buildNumber: String? {
        plist?["CFBundleVersion"] as? String
    }

    public var displayName: String? {
        plist?["CFBundleDisplayName"] as? String ?? plist?["CFBundleName"] as? String
    }

    /// Info.plist의 CFBundleIcons → CFBundlePrimaryIcon → CFBundleIconFiles에서 아이콘 파일명을 찾아 .app 내 실제 PNG 로드
    public var iconImage: NSImage? {
        guard let icons = plist?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let iconName = iconFiles.first else { return nil }

        // 60x60@2x를 우선 찾고, 없으면 이름 매칭
        let candidates = [
            "\(iconName)@2x.png",
            "\(iconName)60x60@2x.png",
            "\(iconName).png"
        ]

        for candidate in candidates {
            let iconURL = appURL.appendingPathComponent(candidate)
            if let image = NSImage(contentsOf: iconURL) { return image }
        }

        // fallback: 이름에 매칭되는 파일 찾기
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: appURL.path) {
            for file in contents where file.hasPrefix(iconName) && file.hasSuffix(".png") {
                let iconURL = appURL.appendingPathComponent(file)
                if let image = NSImage(contentsOf: iconURL) { return image }
            }
        }

        return nil
    }

    /// 폴더명에서 rc 정보 추출 (예: "18.18.0-rc.0+devDebug")
    public var folderVersionInfo: String? {
        let folderName = appURL.deletingLastPathComponent().lastPathComponent
        // "18.17.0-rc.3+devDebug" 패턴 매칭
        guard let regex = try? NSRegularExpression(pattern: #"(\d+\.\d+\.\d+(?:-rc\.\d+)?(?:\+\w+)?)"#),
              let match = regex.firstMatch(in: folderName, range: NSRange(folderName.startIndex..., in: folderName)),
              let range = Range(match.range(at: 1), in: folderName) else { return nil }
        return String(folderName[range])
    }
}
