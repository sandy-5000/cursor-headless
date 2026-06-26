import AppKit
import SwiftUI

struct LineSpacedTextEditor: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var lineSpacing: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true

        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.isRichText = false
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = .zero
        textView.font = .systemFont(ofSize: fontSize)
        textView.string = text
        applyParagraphStyle(to: textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        textView.font = .systemFont(ofSize: fontSize)
        applyParagraphStyle(to: textView)

        if textView.string != text {
            textView.string = text
            applyParagraphStyle(to: textView)
        }
    }

    private func applyParagraphStyle(to textView: NSTextView) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        textView.defaultParagraphStyle = style
        textView.typingAttributes[.paragraphStyle] = style

        let range = NSRange(location: 0, length: (textView.string as NSString).length)
        guard range.length > 0 else { return }
        textView.textStorage?.addAttribute(.paragraphStyle, value: style, range: range)
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LineSpacedTextEditor

        init(parent: LineSpacedTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}
