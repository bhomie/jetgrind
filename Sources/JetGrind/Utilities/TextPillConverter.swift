import AppKit
import Foundation

@MainActor
enum TextPillConverter {
    private static let markerPattern = try! NSRegularExpression(
        pattern: #"\{\{link:([A-Fa-f0-9\-]+)\}\}"#
    )

    // MARK: - Marker format → NSAttributedString

    static func toAttributedString(
        text: String,
        links: [LinkItem],
        font: NSFont,
        color: NSColor
    ) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let linkById = Dictionary(uniqueKeysWithValues: links.map { ($0.id.uuidString.uppercased(), $0) })

        let nsText = text as NSString
        let fullRange = NSRange(location: 0, length: nsText.length)
        let matches = markerPattern.matches(in: text, range: fullRange)

        var cursor = text.startIndex
        for match in matches {
            guard let matchRange = Range(match.range, in: text),
                  let uuidRange = Range(match.range(at: 1), in: text) else { continue }

            // Append text before marker
            if cursor < matchRange.lowerBound {
                let segment = String(text[cursor..<matchRange.lowerBound])
                result.append(NSAttributedString(string: segment, attributes: [
                    .font: font,
                    .foregroundColor: color,
                ]))
            }

            // Append pill attachment or placeholder
            let uuidStr = String(text[uuidRange]).uppercased()
            if let link = linkById[uuidStr] {
                let attachment = NSTextAttachment()
                attachment.attachmentCell = PillAttachmentCell(link: link)
                result.append(NSAttributedString(attachment: attachment))
            } else {
                // Unknown link ID — keep marker as text
                let marker = String(text[matchRange])
                result.append(NSAttributedString(string: marker, attributes: [
                    .font: font,
                    .foregroundColor: color,
                ]))
            }

            cursor = matchRange.upperBound
        }

        // Append remaining text
        if cursor < text.endIndex {
            let segment = String(text[cursor...])
            result.append(NSAttributedString(string: segment, attributes: [
                .font: font,
                .foregroundColor: color,
            ]))
        }

        return result
    }

    // MARK: - NSAttributedString → marker format

    static func fromAttributedString(_ attrStr: NSAttributedString) -> (text: String, links: [LinkItem]) {
        var text = ""
        var links: [LinkItem] = []
        let fullRange = NSRange(location: 0, length: attrStr.length)

        attrStr.enumerateAttributes(in: fullRange) { attrs, range, _ in
            if let attachment = attrs[.attachment] as? NSTextAttachment,
               let cell = attachment.attachmentCell as? PillAttachmentCell {
                let link = cell.link
                text += "{{link:\(link.id.uuidString)}}"
                if !links.contains(where: { $0.id == link.id }) {
                    links.append(link)
                }
            } else {
                text += attrStr.attributedSubstring(from: range).string
            }
        }

        return (text, links)
    }

    // MARK: - Legacy migration

    static func migrateRawURLs(text: String, existingLinks: [LinkItem]) -> (text: String, links: [LinkItem]) {
        let matches = URLDetector.extractMatches(from: text)
        guard !matches.isEmpty else { return (text, existingLinks) }

        let existingByURL = Dictionary(uniqueKeysWithValues: existingLinks.map { ($0.url.absoluteString, $0) })
        var result = text
        var links: [LinkItem] = []

        // Replace in reverse to preserve ranges
        for match in matches.reversed() {
            let link: LinkItem
            if let existing = existingByURL[match.url.absoluteString] {
                link = existing
            } else {
                link = LinkItem(url: match.url)
            }
            if !links.contains(where: { $0.id == link.id }) {
                links.insert(link, at: 0)
            }
            result.replaceSubrange(match.range, with: "{{link:\(link.id.uuidString)}}")
        }

        // Preserve any existing links not in the text
        for existing in existingLinks {
            if !links.contains(where: { $0.id == existing.id }) {
                links.append(existing)
            }
        }

        return (result, links)
    }

    // MARK: - Helpers

    static func containsMarkers(_ text: String) -> Bool {
        let range = NSRange(text.startIndex..., in: text)
        return markerPattern.firstMatch(in: text, range: range) != nil
    }
}
