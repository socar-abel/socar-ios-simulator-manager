import SwiftUI
import AppKit

/// macOS에서 List 옆에 있어도 키보드 입력이 확실히 되는 TextField
public struct FocusableTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String
    var onSubmit: (() -> Void)?

    public init(_ placeholder: String, text: Binding<String>, onSubmit: (() -> Void)? = nil) {
        self.placeholder = placeholder
        self._text = text
        self.onSubmit = onSubmit
    }

    public func makeNSView(context: Context) -> ClickableTextField {
        let field = ClickableTextField()
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.bezelStyle = .roundedBezel
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.lineBreakMode = .byTruncatingTail
        field.cell?.truncatesLastVisibleLine = true
        return field
    }

    public func updateNSView(_ nsView: ClickableTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, NSTextFieldDelegate {
        let parent: FocusableTextField

        init(_ parent: FocusableTextField) {
            self.parent = parent
        }

        public func controlTextDidChange(_ obj: Notification) {
            guard let field = obj.object as? NSTextField else { return }
            parent.text = field.stringValue
        }

        public func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                parent.onSubmit?()
                return true
            }
            return false
        }
    }
}

/// 클릭 시 자동으로 first responder를 가져오는 NSTextField
public class ClickableTextField: NSTextField {
    public override func mouseDown(with event: NSEvent) {
        // 앱 자체를 활성화 + 윈도우를 key window로
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.window?.makeKeyAndOrderFront(nil)
        super.mouseDown(with: event)
        self.window?.makeFirstResponder(self)
    }

    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        // 포커스 획득 시 전체 텍스트 선택
        if result, let editor = currentEditor() {
            editor.selectAll(nil)
        }
        return result
    }
}
