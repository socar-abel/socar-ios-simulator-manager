import Foundation
import os.log

private let logger = Logger(subsystem: "com.socar.simulator-manager", category: "Shell")

public actor ShellService {

    public struct CommandResult: Sendable {
        public let exitCode: Int32
        public let stdout: String
        public let stderr: String

        public var isSuccess: Bool { exitCode == 0 }
    }

    public enum ShellError: LocalizedError {
        case launchFailed(Error)
        case timeout(executable: String, seconds: TimeInterval)
        case nonZeroExit(code: Int32, stderr: String)
        case executableNotFound(String)

        public var errorDescription: String? {
            switch self {
            case .launchFailed(let error):
                return "프로세스 실행 실패: \(error.localizedDescription)"
            case .timeout(let executable, let seconds):
                return "\(executable) 명령이 \(Int(seconds))초 내에 완료되지 않았습니다."
            case .nonZeroExit(let code, let stderr):
                return "명령 실패 (코드 \(code)): \(stderr)"
            case .executableNotFound(let name):
                return "\(name)을(를) 찾을 수 없습니다."
            }
        }
    }

    private let xcrunPath: String

    public init() async throws {
        let result = try await Self.execute(
            executable: "/usr/bin/which",
            arguments: ["xcrun"],
            timeout: 5
        )
        guard result.isSuccess,
              !result.stdout.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ShellError.executableNotFound("xcrun")
        }
        self.xcrunPath = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func run(
        executable: String,
        arguments: [String] = [],
        timeout: TimeInterval = 30
    ) async throws -> CommandResult {
        try await Self.execute(executable: executable, arguments: arguments, timeout: timeout)
    }

    public func simctl(_ arguments: String...) async throws -> CommandResult {
        try await simctlArgs(arguments)
    }

    public func simctlArgs(_ arguments: [String]) async throws -> CommandResult {
        try await run(executable: xcrunPath, arguments: ["simctl"] + arguments)
    }

    // MARK: - Static

    public static func execute(
        executable: String,
        arguments: [String],
        timeout: TimeInterval
    ) async throws -> CommandResult {
        logger.debug("실행: \(executable) \(arguments.joined(separator: " "))")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        var env = ProcessInfo.processInfo.environment
        let extraPaths = ["/usr/bin", "/usr/local/bin", "/opt/homebrew/bin"]
        let currentPath = env["PATH"] ?? ""
        env["PATH"] = (extraPaths + [currentPath]).joined(separator: ":")
        process.environment = env

        return try await withThrowingTaskGroup(of: CommandResult?.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { continuation in
                    do {
                        try process.run()
                    } catch {
                        logger.error("프로세스 시작 실패: \(error.localizedDescription)")
                        continuation.resume(throwing: ShellError.launchFailed(error))
                        return
                    }

                    DispatchQueue.global(qos: .userInitiated).async {
                        let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                        process.waitUntilExit()

                        let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                        let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                        logger.debug("완료: \(executable) - exitCode: \(process.terminationStatus)")
                        continuation.resume(returning: CommandResult(
                            exitCode: process.terminationStatus,
                            stdout: stdout,
                            stderr: stderr
                        ))
                    }
                }
            }

            group.addTask {
                try await Task.sleep(for: .seconds(timeout))
                if process.isRunning {
                    logger.warning("타임아웃: \(executable) (\(timeout)초)")
                    process.terminate()
                }
                throw ShellError.timeout(executable: executable, seconds: timeout)
            }

            guard let result = try await group.next() else {
                throw ShellError.timeout(executable: executable, seconds: timeout)
            }
            group.cancelAll()

            if let result { return result }
            throw ShellError.timeout(executable: executable, seconds: timeout)
        }
    }
}
