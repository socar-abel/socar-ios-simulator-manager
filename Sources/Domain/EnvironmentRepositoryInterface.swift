import Foundation

public protocol EnvironmentRepositoryInterface: Sendable {
    func findXcodePath() async -> String?
    func findXcodeVersion() async -> String?
    func isSimctlAvailable() async -> Bool
    func findAvailableRuntimes() async -> [String]
}
