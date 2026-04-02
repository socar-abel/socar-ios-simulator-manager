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
        LocationPreset(id: "gangnam", name: "강남역", emoji: "🏙️", latitude: 37.4979, longitude: 127.0276),
        LocationPreset(id: "seoul_forest", name: "서울숲역", emoji: "🌳", latitude: 37.5437, longitude: 127.0448),
        LocationPreset(id: "jeju_airport", name: "제주공항", emoji: "✈️", latitude: 33.5104, longitude: 126.4914),
        LocationPreset(id: "busan", name: "부산역", emoji: "🌊", latitude: 35.1152, longitude: 129.0422),
    ]
}
