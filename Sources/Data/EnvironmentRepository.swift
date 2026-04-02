import Foundation
import Core
import Domain

public struct EnvironmentRepository: EnvironmentRepositoryInterface {

    public init() {}

    public func findXcodePath() async -> String? {
        // 1) xcode-select -p 결과 확인
        let selectResult = try? await ShellService.execute(
            executable: "/usr/bin/xcode-select", arguments: ["-p"], timeout: AppConstants.Timeout.environmentShort
        )
        let selectedPath = selectResult?.isSuccess == true
            ? selectResult!.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            : nil

        // 2) xcode-select가 Xcode.app을 가리키면 그대로 사용
        if let selectedPath, selectedPath.contains("Xcode") && selectedPath.contains(".app") {
            return selectedPath
        }

        // 3) 기본 경로에 Xcode.app이 있는지 확인
        let defaultPath = "/Applications/Xcode.app/Contents/Developer"
        if FileManager.default.fileExists(atPath: defaultPath) {
            return defaultPath
        }

        // 4) /Applications 에서 Xcode*.app 검색
        if let apps = try? FileManager.default.contentsOfDirectory(atPath: "/Applications") {
            for app in apps where app.hasPrefix("Xcode") && app.hasSuffix(".app") {
                let devPath = "/Applications/\(app)/Contents/Developer"
                if FileManager.default.fileExists(atPath: devPath) {
                    return devPath
                }
            }
        }

        return nil
    }

    public func findXcodeVersion() async -> String? {
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcodebuild", arguments: ["-version"], timeout: AppConstants.Timeout.environmentShort
        ), result.isSuccess else { return nil }
        return result.stdout.components(separatedBy: "\n").first
    }

    public func hasDeveloperTools() async -> Bool {
        // xcode-select -p 가 성공하면 CLT든 Xcode든 뭔가 설치되어 있음
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcode-select", arguments: ["-p"], timeout: AppConstants.Timeout.environmentShort
        ) else { return false }
        return result.isSuccess
    }

    public func isSimctlAvailable() async -> Bool {
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcrun", arguments: ["simctl", "help"], timeout: AppConstants.Timeout.environmentShort
        ) else { return false }
        return result.isSuccess
    }

    public func findAvailableRuntimes() async -> [String] {
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcrun",
            arguments: ["simctl", "list", "runtimes", "--json"],
            timeout: AppConstants.Timeout.environmentLong
        ), result.isSuccess,
              let data = result.stdout.data(using: .utf8) else { return [] }

        struct RuntimesResponse: Codable {
            struct Runtime: Codable {
                let name: String
                let isAvailable: Bool
            }
            let runtimes: [Runtime]
        }

        guard let json = try? JSONDecoder().decode(RuntimesResponse.self, from: data) else { return [] }
        return json.runtimes.filter(\.isAvailable).map(\.name)
    }
}
