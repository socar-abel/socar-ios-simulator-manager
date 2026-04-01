import Foundation

public enum AppConstants {

    // MARK: - Polling

    public enum Polling {
        /// 디바이스 상태 폴링 최대 횟수
        public static let deviceStateMaxAttempts = 10
        /// 디바이스 상태 폴링 간격 (ms)
        public static let deviceStateIntervalMs = 500

        /// iOS 버전 삭제 확인 폴링 최대 횟수
        public static let iosVersionDeleteMaxAttempts = 30
        /// iOS 버전 삭제 확인 폴링 간격 (초)
        public static let iosVersionDeleteIntervalSeconds = 2

        /// Unusable 상태 자동 폴링 최대 횟수
        public static let unusableMaxAttempts = 60
        /// Unusable 상태 자동 폴링 간격 (초)
        public static let unusableIntervalSeconds = 5
    }

    // MARK: - Timeouts

    public enum Timeout {
        /// 기본 셸 명령 타임아웃 (초)
        public static let shellDefault: TimeInterval = 30
        /// 다운로드 타임아웃 (초)
        public static let download: TimeInterval = 3600
        /// 환경 체크 짧은 타임아웃 (초)
        public static let environmentShort: TimeInterval = 5
        /// 환경 체크 긴 타임아웃 (초)
        public static let environmentLong: TimeInterval = 10
    }

    // MARK: - Toast

    public enum Toast {
        /// 성공 토스트 자동 닫기 시간 (초)
        public static let autoDismissSeconds: UInt64 = 3
    }

    // MARK: - URLs

    public static let googleDriveURL = "https://drive.google.com/drive/folders/1GC85ktjO9OInB5IEVf7Wzd3laLuTegTs"

    // MARK: - Design

    public enum DesignConstants {
        public static let defaultPadding: CGFloat = 16
        public static let sectionSpacing: CGFloat = 24
        public static let cardCornerRadius: CGFloat = 10
        public static let bannerCornerRadius: CGFloat = 8
        public static let bannerPadding: CGFloat = 12
    }
}
