import AppKit
import SwiftUI

final class LinkTextView: NSTextView {
    var onLinkClick: ((URL) -> Void)?

    override func mouseDown(with event: NSEvent) {
        if let url = linkURL(at: event) {
            onLinkClick?(url)
            return
        }
        super.mouseDown(with: event)
    }

    override func resetCursorRects() {
        super.resetCursorRects()
        guard let textStorage, let layoutManager, let textContainer else { return }

        let fullRange = NSRange(location: 0, length: textStorage.length)
        textStorage.enumerateAttribute(.link, in: fullRange) { value, range, _ in
            guard value != nil else { return }
            let glyphRange = layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
            layoutManager.enumerateEnclosingRects(forGlyphRange: glyphRange, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), in: textContainer) { rect, _ in
                self.addCursorRect(rect, cursor: .pointingHand)
            }
        }
    }

    private func linkURL(at event: NSEvent) -> URL? {
        let point = convert(event.locationInWindow, from: nil)
        guard let layoutManager, let textContainer else { return nil }

        let index = layoutManager.characterIndex(
            for: point,
            in: textContainer,
            fractionOfDistanceBetweenInsertionPoints: nil
        )

        guard index < textStorage!.length else { return nil }

        if let url = textStorage?.attribute(.link, at: index, effectiveRange: nil) as? URL {
            return url
        }
        if let urlString = textStorage?.attribute(.link, at: index, effectiveRange: nil) as? String {
            return URL(string: urlString)
        }
        return nil
    }
}

struct LineSpacedTextEditor: NSViewRepresentable {
    @Binding var text: String
    var fontSize: CGFloat
    var lineSpacing: CGFloat
    var linkColor: NSColor
    var onOpenLink: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true

        let textView = LinkTextView()
        textView.onLinkClick = { url in
            context.coordinator.parent.onOpenLink(url)
        }
        textView.isRichText = false
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainerInset = .zero
        textView.isEditable = true
        textView.isSelectable = true
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: fontSize)
        textView.string = text

        scrollView.documentView = textView
        configure(textView)
        NoteLinkHighlighter.apply(to: textView, linkColor: linkColor)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? LinkTextView else { return }

        context.coordinator.parent = self
        textView.onLinkClick = { url in
            context.coordinator.parent.onOpenLink(url)
        }

        textView.font = .systemFont(ofSize: fontSize)
        configure(textView)

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            NoteLinkHighlighter.apply(to: textView, linkColor: linkColor)
            textView.selectedRanges = selectedRanges
        } else {
            NoteLinkHighlighter.apply(to: textView, linkColor: linkColor)
        }
    }

    private func configure(_ textView: NSTextView) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineSpacing
        textView.defaultParagraphStyle = style
        textView.typingAttributes = [
            .font: NSFont.systemFont(ofSize: fontSize),
            .paragraphStyle: style,
            .foregroundColor: NSColor.labelColor,
        ]
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: LineSpacedTextEditor

        init(parent: LineSpacedTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let selectedRanges = textView.selectedRanges
            parent.text = textView.string
            NoteLinkHighlighter.apply(to: textView, linkColor: parent.linkColor)
            textView.selectedRanges = selectedRanges
            textView.resetCursorRects()
        }

        func textView(_ textView: NSTextView, clickedOnLink link: Any, at charIndex: Int) -> Bool {
            if let url = link as? URL {
                parent.onOpenLink(url)
                return true
            }
            if let urlString = link as? String, let url = URL(string: urlString) {
                parent.onOpenLink(url)
                return true
            }
            return false
        }
    }
}
