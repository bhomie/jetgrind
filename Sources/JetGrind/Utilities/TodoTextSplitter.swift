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
        let urls = URLDetector.extractURLs(from: trimmed)
        let links = urls.map { LinkItem(url: $0) }

        // If the entire input is a single URL, use domain as title
        if URLDetector.isSingleURL(trimmed) {
            let domain = urls.first?.host() ?? trimmed
            return Result(title: domain, description: nil, links: links)
        }

        guard trimmed.count > characterLimit else {
            return Result(title: trimmed, description: nil, links: links)
        }

        // Split at last word boundary before the limit
        let prefix = String(trimmed.prefix(characterLimit))
        if let lastSpace = prefix.lastIndex(of: " ") {
            let title = String(prefix[prefix.startIndex..<lastSpace])
            let rest = String(trimmed[lastSpace...]).trimmingCharacters(in: .whitespacesAndNewlines)
            let description = rest.isEmpty ? nil : rest
            return Result(title: title, description: description, links: links)
        }

        // No word boundary found — just split at the limit
        let title = prefix
        let rest = String(trimmed.dropFirst(characterLimit)).trimmingCharacters(in: .whitespacesAndNewlines)
        let description = rest.isEmpty ? nil : rest
        return Result(title: title, description: description, links: links)
    }
}
