import Foundation

enum URLDetector {
    private static let urlPattern = try! NSRegularExpression(
        pattern: #"https?://[^\s<>"']+"#,
        options: [.caseInsensitive]
    )

    static func extractURLs(from text: String) -> [URL] {
        let range = NSRange(text.startIndex..., in: text)
        return urlPattern.matches(in: text, range: range).compactMap { match in
            guard let range = Range(match.range, in: text) else { return nil }
            return URL(string: String(text[range]))
        }
    }

    static func removeURLs(from text: String) -> String {
        let range = NSRange(text.startIndex..., in: text)
        let cleaned = urlPattern.stringByReplacingMatches(in: text, range: range, withTemplate: "")
        return cleaned.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func extractMatches(from text: String) -> [(url: URL, range: Range<String.Index>)] {
        let range = NSRange(text.startIndex..., in: text)
        return urlPattern.matches(in: text, range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: text),
                  let url = URL(string: String(text[swiftRange])) else { return nil }
            return (url: url, range: swiftRange)
        }
    }

    static func isSingleURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed),
              let scheme = url.scheme,
              ["http", "https"].contains(scheme.lowercased()) else {
            return false
        }
        return URLDetector.removeURLs(from: trimmed).isEmpty
    }
}
