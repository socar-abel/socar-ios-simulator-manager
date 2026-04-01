import Foundation

/// 시뮬레이터 위치 테스트용 프리셋
public struct LocationPreset: Identifiable {
    public let id: String
    public let name: String
    public let emoji: String
    public let latitude: Double
    public let longitude: Double

    public init(id: String, name: String, emoji: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.latitude = latitude
        self.longitude = longitude
    }

    public static let all: [LocationPreset] = [
        // 서울 주요 지역
        LocationPreset(id: "gangnam", name: "강남역", emoji: "🏙️", latitude: 37.4979, longitude: 127.0276),
        LocationPreset(id: "hongdae", name: "홍대입구", emoji: "🎸", latitude: 37.5563, longitude: 126.9236),
        LocationPreset(id: "seoul_station", name: "서울역", emoji: "🚂", latitude: 37.5547, longitude: 126.9707),
        LocationPreset(id: "jamsil", name: "잠실", emoji: "⚾", latitude: 37.5133, longitude: 127.1001),
        LocationPreset(id: "yeouido", name: "여의도", emoji: "🏢", latitude: 37.5219, longitude: 126.9245),

        // 쏘카 관련
        LocationPreset(id: "socar_hq", name: "쏘카 본사 (제주)", emoji: "🚗", latitude: 33.4506, longitude: 126.5703),
        LocationPreset(id: "jeju_airport", name: "제주공항", emoji: "✈️", latitude: 33.5104, longitude: 126.4914),

        // 기타 주요 도시
        LocationPreset(id: "busan", name: "부산역", emoji: "🌊", latitude: 35.1152, longitude: 129.0422),
        LocationPreset(id: "incheon_airport", name: "인천공항", emoji: "🛬", latitude: 37.4602, longitude: 126.4407),
        LocationPreset(id: "pangyo", name: "판교역", emoji: "💻", latitude: 37.3948, longitude: 127.1112),
    ]
}
