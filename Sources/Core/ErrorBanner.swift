import SwiftUI

public struct ErrorBanner: View {

    public let message: String
    public let onDismiss: () -> Void

    public init(message: String, onDismiss: @escaping () -> Void) {
        self.message = message
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            Text(message)
                .font(.callout)
            Spacer()
            Button("닫기") { onDismiss() }
                .buttonStyle(.borderless)
        }
        .padding(12)
        .background(.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
