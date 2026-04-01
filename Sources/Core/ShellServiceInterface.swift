import Foundation

public protocol ShellServiceInterface: Actor {
    func run(
        executable: String,
        arguments: [String],
        timeout: TimeInterval
    ) async throws -> ShellService.CommandResult

    func simctl(_ arguments: String...) async throws -> ShellService.CommandResult

    func simctlArgs(_ arguments: [String]) async throws -> ShellService.CommandResult

    func runWithProgress(
        executable: String,
        arguments: [String],
        timeout: TimeInterval,
        onOutputLine: @Sendable @escaping (String) -> Void
    ) async throws -> ShellService.CommandResult
}

public extension ShellServiceInterface {
    func run(
        executable: String,
        arguments: [String] = [],
        timeout: TimeInterval = AppConstants.Timeout.shellDefault
    ) async throws -> ShellService.CommandResult {
        try await run(executable: executable, arguments: arguments, timeout: timeout)
    }

    func runWithProgress(
        executable: String,
        arguments: [String] = [],
        timeout: TimeInterval = AppConstants.Timeout.download,
        onOutputLine: @Sendable @escaping (String) -> Void
    ) async throws -> ShellService.CommandResult {
        try await runWithProgress(
            executable: executable,
            arguments: arguments,
            timeout: timeout,
            onOutputLine: onOutputLine
        )
    }
}

extension ShellService: ShellServiceInterface {}
