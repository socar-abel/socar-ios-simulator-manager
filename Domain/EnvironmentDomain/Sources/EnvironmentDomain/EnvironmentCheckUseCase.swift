import Foundation
import os.log
import ShellKit

private let logger = Logger(subsystem: "com.socar.simulator-manager", category: "Environment")

public struct EnvironmentCheckUseCase: Sendable {

    public init() {}

    public func check() async -> EnvironmentStatus {
        logger.info("환경 확인 시작")

        async let xcodePath = findXcodePath()
        async let xcodeVersion = findXcodeVersion()
        async let runtimes = findRuntimes()

        let path = await xcodePath
        let version = await xcodeVersion
        let runtimeList = await runtimes

        logger.info("Xcode: \(path ?? "nil"), 런타임: \(runtimeList.count)개")

        return EnvironmentStatus(
            xcodeInstalled: path != nil,
            xcodePath: path,
            xcodeVersion: version,
            commandLineToolsInstalled: path != nil,
            availableRuntimes: runtimeList
        )
    }

    // MARK: - Private

    private func findXcodePath() async -> String? {
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcode-select", arguments: ["-p"], timeout: 5
        ), result.isSuccess else { return nil }
        return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func findXcodeVersion() async -> String? {
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcodebuild", arguments: ["-version"], timeout: 5
        ), result.isSuccess else { return nil }
        return result.stdout.components(separatedBy: "\n").first
    }

    private func findRuntimes() async -> [String] {
        guard let result = try? await ShellService.execute(
            executable: "/usr/bin/xcrun", arguments: ["simctl", "list", "runtimes", "--json"], timeout: 10
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
