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
                productFamily: $0.productFamily
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
                    lastUsedAt: dto.lastUsedAt
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
        return index.downloadables
            .filter { $0.name.contains("iOS") }
            .map { item in
                DownloadableIOSVersion(
                    name: item.name,
                    version: item.version,
                    fileSize: item.fileSize,
                    source: item.source ?? "",
                    contentType: item.contentType ?? ""
                )
            }
    }

    public func deleteIOSVersion(identifier: String) async throws {
        let result = try await dependency.shell.simctlArgs(["runtime", "delete", identifier])
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
        }
    }

    public func downloadIOSVersion(platform: String) async throws {
        // xcodebuild -downloadPlatform iOS (장시간 소요)
        let result = try await dependency.shell.run(
            executable: "/usr/bin/xcodebuild",
            arguments: ["-downloadPlatform", platform],
            timeout: 3600  // iOS 버전 다운로드는 최대 1시간
        )
        guard result.isSuccess else {
            throw SimulatorRepositoryError.commandFailed(result.stderr)
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
            return "시뮬레이터 명령 실패: \(reason)"
        }
    }
}
