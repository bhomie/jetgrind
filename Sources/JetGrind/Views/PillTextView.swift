import AppKit
import SwiftUI

// MARK: - PillNSTextView

final class PillNSTextView: NSTextView {
    var isSingleLine = false
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?
    var onNavigateUp: (() -> Void)?
    var onNavigateDown: (() -> Void)?
    var onFocusChange: ((Bool) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result { onFocusChange?(true) }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result { onFocusChange?(false) }
        return result
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        switch event.keyCode {
        case 36: // Return
            if flags.contains(.shift) && !isSingleLine {
                // Shift+Enter: newline in description
                insertNewline(nil)
            } else {
                onCommit?()
            }
        case 53: // Escape
            onCancel?()
        case 126: // Up arrow
            if isCursorOnFirstLine() {
                onNavigateUp?()
            } else {
                super.keyDown(with: event)
            }
        case 125: // Down arrow
            if isSingleLine || isCursorOnLastLine() {
                onNavigateDown?()
            } else {
                super.keyDown(with: event)
            }
        case 48: // Tab
            if flags.contains(.shift) {
                onNavigateUp?()
            } else {
                onNavigateDown?()
            }
        default:
            super.keyDown(with: event)
        }
    }

    override func paste(_ sender: Any?) {
        guard let pasteboard = NSPasteboard.general.string(forType: .string) else {
            super.paste(sender)
            return
        }

        let matches = URLDetector.extractMatches(from: pasteboard)
        if matches.isEmpty {
            super.paste(sender)
            return
        }

        // Build attributed string from pasted text with URL pills
        let font = self.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let color = self.textColor ?? NSColor.textColor
        var text = pasteboard
        var links: [LinkItem] = []

        // Replace URLs with markers (reverse order to preserve ranges)
        for match in matches.reversed() {
            let link = LinkItem(url: match.url)
            links.insert(link, at: 0)
            text.replaceSubrange(match.range, with: "{{link:\(link.id.uuidString)}}")
        }

        let attrStr = TextPillConverter.toAttributedString(text: text, links: links, font: font, color: color)
        let storage = textStorage!
        let insertionRange = selectedRange()
        storage.replaceCharacters(in: insertionRange, with: attrStr)
        setSelectedRange(NSRange(location: insertionRange.location + attrStr.length, length: 0))
    }

    // MARK: - Cursor position detection

    private func isCursorOnFirstLine() -> Bool {
        guard let lm = layoutManager, let tc = textContainer else { return true }
        let insertionPoint = selectedRange().location
        var firstLineGlyphRange = NSRange()
        lm.lineFragmentRect(forGlyphAt: 0, effectiveRange: &firstLineGlyphRange)
        let firstLineCharRange = lm.characterRange(forGlyphRange: firstLineGlyphRange, actualGlyphRange: nil)
        return NSLocationInRange(insertionPoint, firstLineCharRange) || insertionPoint == 0
    }

    private func isCursorOnLastLine() -> Bool {
        guard let lm = layoutManager, let tc = textContainer, let ts = textStorage else { return true }
        let insertionPoint = selectedRange().location
        let lastGlyph = max(lm.numberOfGlyphs - 1, 0)
        var lastLineGlyphRange = NSRange()
        lm.lineFragmentRect(forGlyphAt: lastGlyph, effectiveRange: &lastLineGlyphRange)
        let lastLineCharRange = lm.characterRange(forGlyphRange: lastLineGlyphRange, actualGlyphRange: nil)
        return NSLocationInRange(insertionPoint, lastLineCharRange) || insertionPoint >= ts.length
    }
}

// MARK: - PillTextView (NSViewRepresentable)

struct PillTextView: NSViewRepresentable {
    @Binding var text: String
    @Binding var links: [LinkItem]
    var isEditable: Bool
    var isSingleLine: Bool
    var font: NSFont = .systemFont(ofSize: Theme.Font.titleMedium, weight: .medium)
    var textColor: NSColor = .labelColor
    var placeholderText: String?
    var onCommit: (() -> Void)?
    var onCancel: (() -> Void)?
    var onNavigateUp: (() -> Void)?
    var onNavigateDown: (() -> Void)?
    @Binding var isFocused: Bool
    @Binding var height: CGFloat

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textStorage = NSTextStorage()
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)

        let textContainer = NSTextContainer(containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        textContainer.widthTracksTextView = true
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)

        let textView = PillNSTextView(frame: .zero, textContainer: textContainer)
        textView.drawsBackground = false
        textView.isEditable = isEditable
        textView.isSelectable = true
        textView.isRichText = true
        textView.isFieldEditor = isSingleLine
        textView.isSingleLine = isSingleLine
        textView.font = font
        textView.textColor = textColor
        textView.delegate = context.coordinator
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.allowsUndo = true
        textView.textContainerInset = NSSize(width: 0, height: 0)

        textView.onCommit = onCommit
        textView.onCancel = onCancel
        textView.onNavigateUp = onNavigateUp
        textView.onNavigateDown = onNavigateDown
        let coordinator = context.coordinator
        textView.onFocusChange = { [weak coordinator] focused in
            guard let coordinator else { return }
            if !coordinator.isUpdatingFromSwiftUI {
                DispatchQueue.main.async {
                    coordinator.parent.isFocused = focused
                }
            }
        }

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.drawsBackground = false
        scrollView.hasVerticalScroller = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        if isSingleLine {
            textView.isVerticallyResizable = false
            textView.isHorizontallyResizable = false
            textContainer.maximumNumberOfLines = 1
            textContainer.lineBreakMode = .byTruncatingTail
        } else {
            textView.isVerticallyResizable = true
            textView.isHorizontallyResizable = false
            textContainer.maximumNumberOfLines = 0
        }

        context.coordinator.textView = textView

        // Initial content
        let attrStr = TextPillConverter.toAttributedString(text: text, links: links, font: font, color: textColor)
        textStorage.setAttributedString(attrStr)

        DispatchQueue.main.async {
            context.coordinator.updateHeight()
        }

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? PillNSTextView else { return }
        let coordinator = context.coordinator
        coordinator.parent = self

        // Update callbacks
        textView.onCommit = onCommit
        textView.onCancel = onCancel
        textView.onNavigateUp = onNavigateUp
        textView.onNavigateDown = onNavigateDown
        textView.isEditable = isEditable
        textView.isSingleLine = isSingleLine

        guard !coordinator.isUpdatingFromAppKit else { return }

        coordinator.isUpdatingFromSwiftUI = true
        defer { coordinator.isUpdatingFromSwiftUI = false }

        // Only rebuild if text/links changed externally
        let current = TextPillConverter.fromAttributedString(textView.attributedString())
        if current.text != text || !linksMatch(current.links, links) {
            let selection = textView.selectedRange()
            let attrStr = TextPillConverter.toAttributedString(text: text, links: links, font: font, color: textColor)
            textView.textStorage?.setAttributedString(attrStr)
            // Restore selection
            let safeLocation = min(selection.location, attrStr.length)
            textView.setSelectedRange(NSRange(location: safeLocation, length: 0))
        }

        // Handle focus changes
        if isFocused && textView.window?.firstResponder !== textView {
            textView.window?.makeFirstResponder(textView)
        }

        coordinator.updateHeight()
    }

    private func linksMatch(_ a: [LinkItem], _ b: [LinkItem]) -> Bool {
        guard a.count == b.count else { return false }
        return zip(a, b).allSatisfy { $0.id == $1.id && $0.faviconData == $1.faviconData }
    }

    // MARK: - Coordinator

    @MainActor
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PillTextView
        weak var textView: PillNSTextView?
        var isUpdatingFromSwiftUI = false
        var isUpdatingFromAppKit = false

        init(_ parent: PillTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? PillNSTextView,
                  !isUpdatingFromSwiftUI else { return }

            isUpdatingFromAppKit = true
            defer { isUpdatingFromAppKit = false }

            // Auto-detect URLs typed with space/newline
            autoDetectURLs(in: textView)

            let result = TextPillConverter.fromAttributedString(textView.attributedString())
            parent.text = result.text
            parent.links = result.links

            updateHeight()
        }

        func updateHeight() {
            guard let textView = textView,
                  let lm = textView.layoutManager,
                  let tc = textView.textContainer else { return }

            lm.ensureLayout(for: tc)
            let usedRect = lm.usedRect(for: tc)
            let newHeight = max(ceil(usedRect.height) + textView.textContainerInset.height * 2, parent.font.pointSize + 4)
            if abs(newHeight - parent.height) > 0.5 {
                DispatchQueue.main.async {
                    self.parent.height = newHeight
                }
            }
        }

        private func autoDetectURLs(in textView: PillNSTextView) {
            guard let storage = textView.textStorage else { return }
            let fullText = storage.string

            // Only trigger on space, newline, or tab at cursor
            let cursorPos = textView.selectedRange().location
            guard cursorPos > 0 else { return }
            let charIndex = fullText.index(fullText.startIndex, offsetBy: cursorPos - 1, limitedBy: fullText.endIndex) ?? fullText.endIndex
            guard charIndex < fullText.endIndex else { return }
            let lastChar = fullText[charIndex]
            guard lastChar == " " || lastChar == "\n" || lastChar == "\t" else { return }

            // Find the word before cursor (before the trigger character)
            let beforeTrigger = fullText[fullText.startIndex..<charIndex]
            guard let lastSpaceIndex = beforeTrigger.lastIndex(where: { $0 == " " || $0 == "\n" || $0 == "\t" }) else {
                // Word starts at beginning of text
                checkAndConvertURL(in: textView, wordRange: fullText.startIndex..<charIndex)
                return
            }
            let wordStart = fullText.index(after: lastSpaceIndex)
            if wordStart < charIndex {
                checkAndConvertURL(in: textView, wordRange: wordStart..<charIndex)
            }
        }

        private func checkAndConvertURL(in textView: PillNSTextView, wordRange: Range<String.Index>) {
            guard let storage = textView.textStorage else { return }
            let word = String(storage.string[wordRange])

            // Check if it's already an attachment character
            if word.contains("\u{FFFC}") { return }

            let matches = URLDetector.extractMatches(from: word)
            guard let match = matches.first, match.range == word.startIndex..<word.endIndex else { return }

            let nsRange = NSRange(wordRange, in: storage.string)
            let link = LinkItem(url: match.url)
            let font = textView.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
            let color = textView.textColor ?? NSColor.textColor

            let attachment = NSTextAttachment()
            attachment.attachmentCell = PillAttachmentCell(link: link)
            let attrStr = NSAttributedString(attachment: attachment)

            storage.replaceCharacters(in: nsRange, with: attrStr)
            textView.setSelectedRange(NSRange(location: nsRange.location + attrStr.length + 1, length: 0))
        }
    }
}
