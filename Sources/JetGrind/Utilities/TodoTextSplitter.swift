import Foundation

enum TodoTextSplitter {
    static let characterLimit = 60

    struct Result {
        let title: String
        let description: String?
        let links: [LinkItem]
    }

    static func split(_ input: String) -> Result {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)

        // If the entire input is a single URL, use domain as title with marker
        if URLDetector.isSingleURL(trimmed) {
            let urls = URLDetector.extractURLs(from: trimmed)
            let link = LinkItem(url: urls.first!)
            let domain = urls.first?.host() ?? trimmed
            return Result(title: domain, description: nil, links: [link])
        }

        // Replace raw URLs with markers, collect LinkItems
        let matches = URLDetector.extractMatches(from: trimmed)
        var markerText = trimmed
        var links: [LinkItem] = []

        for match in matches.reversed() {
            let link = LinkItem(url: match.url)
            links.insert(link, at: 0)
            markerText.replaceSubrange(match.range, with: "{{link:\(link.id.uuidString)}}")
        }

        guard markerText.count > characterLimit else {
            return Result(title: markerText, description: nil, links: links)
        }

        // Split at last word boundary before the limit
        let prefix = String(markerText.prefix(characterLimit))
        if let lastSpace = prefix.lastIndex(of: " ") {
            let title = String(prefix[prefix.startIndex..<lastSpace])
            let rest = String(markerText[lastSpace...]).trimmingCharacters(in: .whitespacesAndNewlines)
            let description = rest.isEmpty ? nil : rest
            return Result(title: title, description: description, links: links)
        }

        // No word boundary found — just split at the limit
        let title = prefix
        let rest = String(markerText.dropFirst(characterLimit)).trimmingCharacters(in: .whitespacesAndNewlines)
        let description = rest.isEmpty ? nil : rest
        return Result(title: title, description: description, links: links)
    }
}
