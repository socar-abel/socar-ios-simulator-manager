import Foundation
import Core
import Domain

public struct EnvironmentRepository: EnvironmentRepositoryInterface {

    public init() {}

    public func findXcodePath() async -> String? {
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcode-select", arguments: ["-p"], timeout: AppConstants.Timeout.environmentShort
        ), result.isSuccess else { return nil }
        let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        // Command Line Tools만 설치된 경우 (/Library/Developer/CommandLineTools) 는 Xcode가 아님
        guard path.contains("Xcode.app") else { return nil }
        return path
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
