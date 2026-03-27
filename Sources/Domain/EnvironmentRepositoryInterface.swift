import Foundation

public protocol EnvironmentRepositoryInterface: Sendable {
    func findXcodePath() async -> String?
    func findXcodeVersion() async -> String?
    func findAvailableRuntimes() async -> [String]
}
