import Foundation

public struct DownloadProgress: Sendable {
    public let percent: Double
    public let downloaded: String
    public let total: String
    public let status: Status

    public enum Status: Sendable {
        case preparing
        case downloading
        case installing
        case completed
        case failed(String)
    }

    public var displayText: String {
        switch status {
        case .preparing:
            return "다운로드 준비 중..."
        case .downloading:
            return "\(String(format: "%.1f", percent))% (\(downloaded) / \(total))"
        case .installing:
            return "설치 중..."
        case .completed:
            return "완료"
        case .failed(let msg):
            return "실패: \(msg)"
        }
    }

    public init(percent: Double = 0, downloaded: String = "", total: String = "", status: Status) {
        self.percent = percent
        self.downloaded = downloaded
        self.total = total
        self.status = status
    }

    /// xcodebuild stdout 라인 파싱
    public static func parse(line: String) -> DownloadProgress? {
        if line.contains("Preparing to download") || line.contains("Finding content") {
            return DownloadProgress(status: .preparing)
        }

        // "15.3% (960 MB of 6.28 GB)"
        let pattern = #"(\d+\.?\d*)%.*\(([\d.]+ [KMGT]?B) of ([\d.]+ [KMGT]?B)\)"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: line, range: NSRange(line.startIndex..., in: line)) {
            let percentStr = String(line[Range(match.range(at: 1), in: line)!])
            let downloaded = String(line[Range(match.range(at: 2), in: line)!])
            let total = String(line[Range(match.range(at: 3), in: line)!])
            let percent = Double(percentStr) ?? 0
            // 100% 도달 시 설치 단계로 전환
            if percent >= 100 {
                return DownloadProgress(percent: 100, downloaded: downloaded, total: total, status: .installing)
            }
            return DownloadProgress(percent: percent, downloaded: downloaded, total: total, status: .downloading)
        }

        // 다운로드 후 설치/검증 단계 메시지
        let lower = line.lowercased()
        if lower.contains("installing") || lower.contains("verifying") || lower.contains("mounting") {
            return DownloadProgress(percent: 100, status: .installing)
        }

        return nil
    }
}
