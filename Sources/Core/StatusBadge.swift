import SwiftUI

public struct StatusBadge: View {

    public let isActive: Bool

    public init(isActive: Bool) {
        self.isActive = isActive
    }

    public var body: some View {
        Circle()
            .fill(isActive ? .green : .gray)
            .frame(width: 8, height: 8)
            .accessibilityLabel(isActive ? "실행중" : "종료됨")
    }
}
