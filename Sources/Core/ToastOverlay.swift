import SwiftUI

/// 에러 배너 + 성공 토스트를 통합하여 제공하는 뷰 모디파이어
public struct ToastOverlay: ViewModifier {

    @Binding var errorMessage: String?
    @Binding var successMessage: String?
    let onDismissError: () -> Void
    let onDismissSuccess: () -> Void

    public func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                VStack(spacing: 8) {
                    if let error = errorMessage {
                        ErrorBanner(message: error, onDismiss: onDismissError)
                            .padding(.horizontal, AppConstants.DesignConstants.defaultPadding)
                    }
                    if let success = successMessage {
                        SuccessToast(message: success, onDismiss: onDismissSuccess)
                            .padding(.horizontal, AppConstants.DesignConstants.defaultPadding)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .task {
                                try? await Task.sleep(for: .seconds(AppConstants.Toast.autoDismissSeconds))
                                await MainActor.run {
                                    withAnimation { onDismissSuccess() }
                                }
                            }
                    }
                }
                .padding(.bottom, AppConstants.DesignConstants.bannerPadding)
            }
            .animation(.easeInOut(duration: 0.25), value: successMessage)
            .animation(.easeInOut(duration: 0.25), value: errorMessage)
    }
}

public struct SuccessToast: View {

    public let message: String
    public let onDismiss: () -> Void

    public init(message: String, onDismiss: @escaping () -> Void) {
        self.message = message
        self.onDismiss = onDismiss
    }

    public var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
            Text(message).font(.callout)
            Spacer()
            Button("닫기") { onDismiss() }.buttonStyle(.borderless)
        }
        .padding(AppConstants.DesignConstants.bannerPadding)
        .background(.green.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: AppConstants.DesignConstants.bannerCornerRadius))
    }
}

public extension View {
    func toastOverlay(
        errorMessage: Binding<String?>,
        successMessage: Binding<String?>,
        onDismissError: @escaping () -> Void,
        onDismissSuccess: @escaping () -> Void
    ) -> some View {
        modifier(ToastOverlay(
            errorMessage: errorMessage,
            successMessage: successMessage,
            onDismissError: onDismissError,
            onDismissSuccess: onDismissSuccess
        ))
    }
}
