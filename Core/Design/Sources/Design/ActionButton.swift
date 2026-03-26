import SwiftUI

public enum ActionButtonStyle {
    case primary, secondary, destructive
}

public struct ActionButton: View {

    public let title: String
    public let icon: String
    public let style: ActionButtonStyle
    public let isDisabled: Bool
    public let action: () -> Void

    public init(
        _ title: String,
        icon: String,
        style: ActionButtonStyle = .secondary,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isDisabled = isDisabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .buttonStyle(.bordered)
        .tint(tintColor)
        .disabled(isDisabled)
    }

    private var tintColor: Color? {
        switch style {
        case .primary: return .blue
        case .secondary: return nil
        case .destructive: return .red
        }
    }
}
