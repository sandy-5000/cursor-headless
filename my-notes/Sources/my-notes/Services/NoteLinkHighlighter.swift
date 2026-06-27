import AppKit

@MainActor
enum NoteLinkHighlighter {
    static func apply(to textView: NSTextView, linkColor: NSColor) {
        guard let textStorage = textView.textStorage else { return }

        let fullRange = NSRange(location: 0, length: textStorage.length)
        guard fullRange.length > 0 else { return }

        textStorage.beginEditing()

        textStorage.removeAttribute(.link, range: fullRange)
        textStorage.removeAttribute(.underlineStyle, range: fullRange)
        textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

        if let font = textView.font {
            textStorage.addAttribute(.font, value: font, range: fullRange)
        }

        if let paragraphStyle = textView.defaultParagraphStyle {
            textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        }

        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            textStorage.endEditing()
            return
        }

        let matches = detector.matches(in: textStorage.string, options: [], range: fullRange)
        for match in matches {
            guard let url = match.url else { continue }
            textStorage.addAttribute(.link, value: url, range: match.range)
            textStorage.addAttribute(.foregroundColor, value: linkColor, range: match.range)
            textStorage.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: match.range)
        }

        textStorage.endEditing()

        textView.linkTextAttributes = [
            .foregroundColor: linkColor,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
        ]
    }
}
