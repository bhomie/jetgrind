import AppKit
import Foundation

final class PillAttachmentCell: NSTextAttachmentCell {
    let link: LinkItem

    nonisolated(unsafe) private static let pillFont = NSFont.systemFont(ofSize: Theme.Size.inlinePillFontSize, weight: .medium)
    nonisolated private static let iconSize = Theme.Size.inlinePillIconSize
    nonisolated private static let pillHeight = Theme.Size.inlinePillHeight
    nonisolated private static let paddingH = Theme.Size.inlinePillPaddingH
    nonisolated private static let internalSpacing: CGFloat = 3

    init(link: LinkItem) {
        self.link = link
        super.init()
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError()
    }

    override func cellSize() -> NSSize {
        let textWidth = (link.displayTitle as NSString).size(withAttributes: [.font: Self.pillFont]).width
        let width = Self.paddingH + Self.iconSize + Self.internalSpacing + textWidth + Self.paddingH
        return NSSize(width: ceil(width), height: Self.pillHeight)
    }

    override func cellBaselineOffset() -> NSPoint {
        NSPoint(x: 0, y: -3)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView?) {
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let accentColor = NSColor.controlAccentColor

        // Capsule background
        let bgColor = accentColor.withAlphaComponent(0.12)
        let path = NSBezierPath(roundedRect: cellFrame, xRadius: cellFrame.height / 2, yRadius: cellFrame.height / 2)
        bgColor.setFill()
        path.fill()

        var x = cellFrame.minX + Self.paddingH

        // Favicon or globe
        let iconRect = NSRect(
            x: x,
            y: cellFrame.midY - Self.iconSize / 2,
            width: Self.iconSize,
            height: Self.iconSize
        )

        if let faviconData = link.faviconData, let image = NSImage(data: faviconData) {
            NSGraphicsContext.saveGraphicsState()
            let clipPath = NSBezierPath(ovalIn: iconRect)
            clipPath.addClip()
            image.draw(in: iconRect)
            NSGraphicsContext.restoreGraphicsState()
        } else {
            let globeImage = NSImage(systemSymbolName: "globe", accessibilityDescription: nil)
            let config = NSImage.SymbolConfiguration(pointSize: Self.iconSize, weight: .regular)
            let configured = globeImage?.withSymbolConfiguration(config)
            let tint = isDark ? NSColor.secondaryLabelColor : NSColor.secondaryLabelColor
            configured?.draw(in: iconRect, from: .zero, operation: .sourceOver, fraction: 1.0)
            // Tint by drawing with template
            if let template = configured {
                template.isTemplate = true
                tint.set()
                template.draw(in: iconRect, from: .zero, operation: .sourceAtop, fraction: 1.0)
            }
        }

        x += Self.iconSize + Self.internalSpacing

        // Domain text
        let textColor = accentColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: Self.pillFont,
            .foregroundColor: textColor,
        ]
        let textSize = (link.displayTitle as NSString).size(withAttributes: attrs)
        let textRect = NSRect(
            x: x,
            y: cellFrame.midY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        (link.displayTitle as NSString).draw(in: textRect, withAttributes: attrs)
    }

    override func wantsToTrackMouse() -> Bool { true }

    override func trackMouse(with theEvent: NSEvent, in cellFrame: NSRect, of controlView: NSView?, untilMouseUp flag: Bool) -> Bool {
        // Wait for mouse-up
        guard let event = controlView?.window?.nextEvent(matching: [.leftMouseUp]) else { return true }
        let point = controlView?.convert(event.locationInWindow, from: nil) ?? .zero
        if cellFrame.contains(point) {
            NSWorkspace.shared.open(link.url)
        }
        return true
    }
}
