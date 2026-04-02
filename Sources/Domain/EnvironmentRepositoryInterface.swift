import Foundation

public protocol EnvironmentRepositoryInterface: Sendable {
    func findXcodePath() async -> String?
    func findXcodeVersion() async -> String?
    func hasDeveloperTools() async -> Bool
    func isSimctlAvailable() async -> Bool
    func findAvailableRuntimes() async -> [String]
}
