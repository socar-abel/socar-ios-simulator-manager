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

    public func makeNSView(context: Context) -> FocusableNSTextField {
        let field = FocusableNSTextField()
        field.placeholderString = placeholder
        field.delegate = context.coordinator
        field.bezelStyle = .roundedBezel
        field.font = .systemFont(ofSize: NSFont.systemFontSize)
        field.lineBreakMode = .byTruncatingTail
        field.cell?.truncatesLastVisibleLine = true
        field.isBordered = true
        field.isBezeled = true
        field.isEditable = true
        field.isSelectable = true
        field.focusRingType = .exterior
        return field
    }

    public func updateNSView(_ nsView: FocusableNSTextField, context: Context) {
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

public class FocusableNSTextField: NSTextField {
    public override var acceptsFirstResponder: Bool { true }

    public override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            currentEditor()?.selectedRange = NSRange(location: stringValue.count, length: 0)
        }
        return result
    }

    public override func mouseDown(with event: NSEvent) {
        // 1. 앱을 활성화
        NSApp.activate(ignoringOtherApps: true)
        // 2. 윈도우를 key window로
        window?.makeKeyAndOrderFront(nil)
        // 3. 기본 mouseDown (텍스트 선택 등)
        super.mouseDown(with: event)
        // 4. 확실하게 first responder
        window?.makeFirstResponder(self)
    }

    // NSViewRepresentable가 포커스를 가로채지 못하게
    public override var needsPanelToBecomeKey: Bool { true }
}
