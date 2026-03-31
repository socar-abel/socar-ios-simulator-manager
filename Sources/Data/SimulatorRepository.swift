import Foundation
import Core
import Domain

public protocol SimulatorRepositoryDependency {
    var shell: ShellService { get }
}

public final class SimulatorRepository<Dependency: SimulatorRepositoryDependency>: SimulatorRepositoryInterface {

    private let dependency: Dependency

    public init(dependency: Dependency) {
        self.dependency = dependency
    }

    public func listDevices() async throws -> [SimulatorDevice] {
        let result = try await dependency.shell.simctl("list", "devices", "--json")
        guard result.isSuccess, let data = result.stdout.data(using: .utf8) else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }

        let response = try JSONDecoder().decode(SimctlDevicesResponse.self, from: data)
        var allDevices: [SimulatorDevice] = []

        for (runtimeKey, deviceList) in response.devices {
            for raw in deviceList where raw.isAvailable {
                allDevices.append(SimulatorDevice(
                    udid: raw.udid,
                    name: raw.name,
                    state: raw.state,
                    isAvailable: raw.isAvailable,
                    deviceTypeIdentifier: raw.deviceTypeIdentifier,
                    runtimeIdentifier: runtimeKey
                ))
            }
        }
        return allDevices.sorted { $0.name < $1.name }
    }

    public func listIOSVersions() async throws -> [SimulatorIOSVersion] {
        let result = try await dependency.shell.simctl("list", "runtimes", "--json")
        guard result.isSuccess, let data = result.stdout.data(using: .utf8) else {
            return []
        }
        let response = try JSONDecoder().decode(SimctlIOSVersionsResponse.self, from: data)
        return response.runtimes
            .filter { $0.isAvailable }
            .map { SimulatorIOSVersion(
                identifier: $0.identifier,
                name: $0.name,
                version: $0.version,
                isAvailable: $0.isAvailable
            )}
    }

    public func listDeviceTypes() async throws -> [SimulatorDeviceType] {
        let result = try await dependency.shell.simctl("list", "devicetypes", "--json")
        guard result.isSuccess, let data = result.stdout.data(using: .utf8) else {
            return []
        }
        let response = try JSONDecoder().decode(SimctlDeviceTypesResponse.self, from: data)
        return response.devicetypes.map {
            SimulatorDeviceType(
                identifier: $0.identifier,
                name: $0.name,
                productFamily: $0.productFamily,
                minRuntimeVersionString: $0.minRuntimeVersionString
            )
        }
    }

    public func createDevice(
        name: String,
        typeIdentifier: String,
        runtimeIdentifier: String
    ) async throws -> String {
        let result = try await dependency.shell.simctlArgs([
            "create", name, typeIdentifier, runtimeIdentifier,
        ])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func bootDevice(udid: String) async throws {
        let result = try await dependency.shell.simctlArgs(["boot", udid])
        guard result.isSuccess || result.stderr.contains("current state: Booted") else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func shutdownDevice(udid: String) async throws {
        let result = try await dependency.shell.simctlArgs(["shutdown", udid])
        guard result.isSuccess || result.stderr.contains("current state: Shutdown") else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func deleteDevice(udid: String) async throws {
        let result = try await dependency.shell.simctlArgs(["delete", udid])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func renameDevice(udid: String, newName: String) async throws {
        let result = try await dependency.shell.simctlArgs(["rename", udid, newName])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func installApp(udid: String, appPath: String) async throws {
        let result = try await dependency.shell.simctlArgs(["install", udid, appPath])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func launchApp(udid: String, bundleId: String) async throws {
        let result = try await dependency.shell.simctlArgs(["launch", udid, bundleId])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func openURL(udid: String, url: String) async throws {
        let result = try await dependency.shell.simctlArgs(["openurl", udid, url])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func openSimulatorApp() async throws {
        _ = try await dependency.shell.run(
            executable: "/usr/bin/open",
            arguments: ["-a", "Simulator"]
        )
    }

    public func loadDeviceTypeProfiles() async throws -> [String: DeviceTypeProfile] {
        // simctl에서 실제 identifier ↔ 이름 매핑 조회
        let typesResult = try await dependency.shell.simctlArgs(["list", "devicetypes", "--json"])
        var nameToIdentifier: [String: String] = [:]
        if typesResult.isSuccess, let jsonData = typesResult.stdout.data(using: .utf8),
           let parsed = try? JSONDecoder().decode(SimctlDeviceTypesResponse.self, from: jsonData) {
            for dt in parsed.devicetypes {
                nameToIdentifier[dt.name] = dt.identifier as String
            }
        }

        let basePath = "/Library/Developer/CoreSimulator/Profiles/DeviceTypes"
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: basePath) else { return [:] }

        var profiles: [String: DeviceTypeProfile] = [:]
        for dir in contents where dir.hasSuffix(".simdevicetype") {
            let plistPath = "\(basePath)/\(dir)/Contents/Resources/profile.plist"
            guard FileManager.default.fileExists(atPath: plistPath),
                  let data = FileManager.default.contents(atPath: plistPath),
                  let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
            else { continue }

            let deviceName = dir.replacingOccurrences(of: ".simdevicetype", with: "")
            guard let identifier = nameToIdentifier[deviceName] else { continue }

            let screenWidth = Self.intValue(plist["mainScreenWidth"]) ?? 0
            let screenHeight = Self.intValue(plist["mainScreenHeight"]) ?? 0
            let screenScale = Self.intValue(plist["mainScreenScale"]) ?? 1
            let sensorBar = plist["sensorBarImage"] as? String ?? "none"
            let hasNotch = sensorBar != "none"

            profiles[identifier] = DeviceTypeProfile(
                identifier: identifier,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                screenScale: screenScale,
                hasNotch: hasNotch
            )
        }
        return profiles
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String, let i = Int(s) { return i }
        return nil
    }

    public func listInstalledApps(udid: String) async throws -> Set<String> {
        let result = try await dependency.shell.simctlArgs(["listapps", udid])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
        // plist → JSON 변환
        let tempPlist = FileManager.default.temporaryDirectory.appendingPathComponent("apps_\(udid).plist")
        let tempJSON = FileManager.default.temporaryDirectory.appendingPathComponent("apps_\(udid).json")
        try result.stdout.data(using: .utf8)?.write(to: tempPlist)
        defer {
            try? FileManager.default.removeItem(at: tempPlist)
            try? FileManager.default.removeItem(at: tempJSON)
        }

        let convertResult = try await dependency.shell.run(
            executable: "/usr/bin/plutil",
            arguments: ["-convert", "json", "-o", tempJSON.path, tempPlist.path]
        )
        guard convertResult.isSuccess else { return [] }

        let jsonData = try Data(contentsOf: tempJSON)
        guard let dict = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return [] }
        return Set(dict.keys)
    }

    public func bringSimulatorToFront() async throws {
        _ = try await dependency.shell.run(
            executable: "/usr/bin/osascript",
            arguments: ["-e", "tell application \"Simulator\" to activate"]
        )
    }

    // MARK: - Runtime Management

    public func listInstalledIOSVersions() async throws -> [InstalledIOSVersion] {
        let result = try await dependency.shell.simctlArgs(["runtime", "list", "-j"])
        guard result.isSuccess, let data = result.stdout.data(using: .utf8) else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }

        let raw = try JSONDecoder().decode([String: SimctlIOSVersionDetailDTO].self, from: data)
        return raw.values
            .filter { $0.platformIdentifier?.contains("iphonesimulator") == true }
            .map { dto in
                InstalledIOSVersion(
                    identifier: dto.identifier,
                    runtimeIdentifier: dto.runtimeIdentifier ?? "",
                    version: dto.version ?? "",
                    sizeBytes: dto.sizeBytes ?? 0,
                    isDeletable: dto.deletable ?? false,
                    state: dto.state ?? "Unknown",
                    lastUsedAt: dto.lastUsedAt,
                    errorMessage: dto.unusableErrorMessage
                )
            }
            .sorted { $0.version > $1.version }
    }

    public func listDownloadableIOSVersions() async throws -> [DownloadableIOSVersion] {
        let url = URL(string: "https://devimages-cdn.apple.com/downloads/xcode/simulators/index2.dvtdownloadableindex")!
        let (data, _) = try await URLSession.shared.data(from: url)

        // plist → JSON 변환: plutil 사용
        let tempPlist = FileManager.default.temporaryDirectory.appendingPathComponent("simindex.plist")
        let tempJSON = FileManager.default.temporaryDirectory.appendingPathComponent("simindex.json")
        try data.write(to: tempPlist)

        let result = try await dependency.shell.run(
            executable: "/usr/bin/plutil",
            arguments: ["-convert", "json", "-o", tempJSON.path, tempPlist.path]
        )
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed("plist 변환 실패")
        }

        let jsonData = try Data(contentsOf: tempJSON)
        try? FileManager.default.removeItem(at: tempPlist)
        try? FileManager.default.removeItem(at: tempJSON)

        let index = try JSONDecoder().decode(DVTDownloadableIndex.self, from: jsonData)

        // 현재 Xcode의 iOS SDK major 버전 확인
        let sdkMajor = await currentIOSSDKMajorVersion()

        return index.downloadables
            .filter {
                $0.name.contains("iOS")
                && $0.isDownloadableOnCurrentMac
                && (sdkMajor == 0 || $0.isCompatibleWithSDK(maxMajor: sdkMajor))
            }
            .map { item in
                DownloadableIOSVersion(
                    name: item.name,
                    version: item.version,
                    fileSize: item.fileSize,
                    source: item.source ?? "",
                    contentType: item.contentType ?? "",
                    buildVersion: item.simulatorVersion?.buildUpdate
                )
            }
    }

    public func deleteIOSVersion(identifier: String) async throws {
        let result = try await dependency.shell.simctlArgs(["runtime", "delete", identifier])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func downloadIOSVersion(platform: String, buildVersion: String?) async throws {
        var args = ["-downloadPlatform", platform]
        if let buildVersion, !buildVersion.isEmpty {
            args += ["-buildVersion", buildVersion]
        }
        let result = try await dependency.shell.run(
            executable: "/usr/bin/xcodebuild",
            arguments: args,
            timeout: 3600
        )
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func downloadIOSVersionWithProgress(
        platform: String,
        buildVersion: String?,
        onProgress: @Sendable @escaping (DownloadProgress) -> Void
    ) async throws {
        var args = ["-downloadPlatform", platform]
        if let buildVersion, !buildVersion.isEmpty {
            args += ["-buildVersion", buildVersion]
        }

        let notAvailableDetected = UnsafeSendableBox(false)

        let result = try await dependency.shell.runWithProgress(
            executable: "/usr/bin/xcodebuild",
            arguments: args,
            timeout: 3600
        ) { line in
            // "not available for download" 감지 시 즉시 에러
            if line.contains("is not available for download") {
                notAvailableDetected.value = true
                return
            }
            if let progress = DownloadProgress.parse(line: line) {
                onProgress(progress)
            }
        }

        if notAvailableDetected.value {
            throw SimulatorRepositoryError.commandFailed(
                "이 iOS 버전은 현재 설치된 Xcode에서 지원하지 않습니다. Xcode를 업데이트해주세요."
            )
        }

        guard result.isSuccess else {
            let stderr = result.stderr
            if stderr.contains("is not available") {
                throw SimulatorRepositoryError.commandFailed(
                    "이 iOS 버전은 현재 설치된 Xcode에서 지원하지 않습니다. Xcode를 업데이트해주세요."
                )
            }
            throw SimulatorRepositoryError.commandFailed(stderr)
        }
    }

    /// Thread-safe wrapper for Sendable closure context
    private final class UnsafeSendableBox<T>: @unchecked Sendable {
        var value: T
        init(_ value: T) { self.value = value }
    }

    // MARK: - SDK Version

    /// 현재 Xcode의 iOS SDK major 버전 (예: Xcode 26.2 → 26)
    private func currentIOSSDKMajorVersion() async -> Int {
        do {
            let result = try await dependency.shell.run(
                executable: "/usr/bin/xcrun",
                arguments: ["--sdk", "iphonesimulator", "--show-sdk-version"]
            )
            guard result.isSuccess else { return 0 }
            let ver = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            return Int(ver.split(separator: ".").first ?? "0") ?? 0
        } catch {
            return 0
        }
    }

    // MARK: - Disk

    public func devicesDiskUsageBytes() async throws -> Int64 {
        let devicesPath = NSHomeDirectory() + "/Library/Developer/CoreSimulator/Devices"
        return directorySize(at: devicesPath)
    }

    public func deleteUnavailableDevices() async throws {
        let result = try await dependency.shell.simctlArgs(["delete", "unavailable"])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    // MARK: - Private

    private func directorySize(at path: String) -> Int64 {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(
            at: URL(fileURLWithPath: path),
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { return 0 }

        var total: Int64 = 0
        for case let url as URL in enumerator {
            if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                total += Int64(size)
            }
        }
        return total
    }
}

public enum SimulatorRepositoryError: LocalizedError {
    case commandFailed(String)

    public var errorDescription: String? {
        switch self {
        case .commandFailed(let reason):
            return Self.friendlyMessage(for: reason)
        }
    }

    private static func friendlyMessage(for stderr: String) -> String {
        let lower = stderr.lowercased()

        // 호환성 문제
        if lower.contains("incompatible device") || lower.contains("code=403") {
            return "이 기기는 선택한 iOS 버전을 지원하지 않습니다. 다른 iOS 버전을 선택해주세요."
        }
        if lower.contains("invalid runtime") || lower.contains("runtime is not available") {
            return "해당 iOS 버전이 설치되어 있지 않습니다. iOS 버전 탭에서 먼저 설치해주세요."
        }
        if lower.contains("is not available for download") {
            return "이 iOS 버전은 현재 Xcode에서 지원하지 않습니다. Xcode를 업데이트해주세요."
        }

        // 부팅 관련
        if lower.contains("unable to boot") || lower.contains("failed to boot") {
            return "시뮬레이터를 실행할 수 없습니다. 다시 시도해주세요."
        }
        if lower.contains("already booted") {
            return "이미 실행 중인 시뮬레이터입니다."
        }

        // 설치 관련
        if lower.contains("no such file") || lower.contains("does not exist") {
            return "파일을 찾을 수 없습니다. 경로를 확인해주세요."
        }
        if lower.contains("not a valid bundle") || lower.contains("invalid bundle") {
            return "유효하지 않은 앱 파일입니다. .app 파일이 맞는지 확인해주세요."
        }

        // 권한/디스크
        if lower.contains("permission denied") || lower.contains("operation not permitted") {
            return "권한이 없습니다. 시스템 설정에서 권한을 확인해주세요."
        }
        if lower.contains("no space left") || lower.contains("disk full") {
            return "디스크 공간이 부족합니다. 불필요한 iOS 버전이나 디바이스를 삭제해주세요."
        }

        // 네트워크
        if lower.contains("network") || lower.contains("connection") || lower.contains("timed out") {
            return "네트워크 연결에 실패했습니다. 인터넷 연결을 확인해주세요."
        }

        // 기타: 원문이 너무 길면 앞부분만
        if stderr.count > 100 {
            return "작업 중 오류가 발생했습니다. 다시 시도해주세요."
        }

        return "오류가 발생했습니다: \(stderr)"
    }
}
