import Foundation

/// 시뮬레이터 푸시 알림 테스트용 프리셋
public struct PushPreset: Identifiable {
    public let id: String
    public let name: String
    public let emoji: String
    public let payload: String

    public init(id: String, name: String, emoji: String, payload: String) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.payload = payload
    }

    public static let all: [PushPreset] = [
        PushPreset(
            id: "reservation",
            name: "예약 알림",
            emoji: "\u{1F697}",
            payload: """
            {
              "aps": {
                "alert": {
                  "title": "쏘카",
                  "body": "예약하신 차량이 준비되었습니다."
                },
                "sound": "default"
              },
              "deeplink": "socar-v2://reservation"
            }
            """
        ),
        PushPreset(
            id: "promotion",
            name: "프로모션",
            emoji: "\u{1F389}",
            payload: """
            {
              "aps": {
                "alert": {
                  "title": "쏘카",
                  "body": "지금 첫 이용 50% 할인 쿠폰을 확인하세요!"
                },
                "sound": "default"
              },
              "deeplink": "socar-v2://promotion"
            }
            """
        ),
        PushPreset(
            id: "return",
            name: "반납 알림",
            emoji: "\u{23F0}",
            payload: """
            {
              "aps": {
                "alert": {
                  "title": "쏘카",
                  "body": "반납 시간이 30분 남았습니다."
                },
                "sound": "default"
              },
              "deeplink": "socar-v2://return"
            }
            """
        ),
    ]
}
