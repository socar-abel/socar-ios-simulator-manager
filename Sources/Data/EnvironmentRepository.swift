import Foundation
import Core
import Domain

public struct EnvironmentRepository: EnvironmentRepositoryInterface {

    public init() {}

    public func findXcodePath() async -> String? {
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcode-select", arguments: ["-p"], timeout: AppConstants.Timeout.environmentShort
        ), result.isSuccess else { return nil }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func findXcodeVersion() async -> String? {
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcodebuild", arguments: ["-version"], timeout: AppConstants.Timeout.environmentShort
        ), result.isSuccess else { return nil }
        return result.stdout.components(separatedBy: "\n").first
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
