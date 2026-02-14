import Foundation

actor LinkMetadataFetcher {
    static let shared = LinkMetadataFetcher()

    private var faviconCache: [String: Data] = [:]
    private var titleCache: [String: String] = [:]
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5
        config.timeoutIntervalForResource = 5
        session = URLSession(configuration: config)
    }

    func fetchFavicon(for url: URL) async -> Data? {
        guard let host = url.host() else { return nil }
        if let cached = faviconCache[host] { return cached }

        guard let faviconURL = URL(string: "https://www.google.com/s2/favicons?domain=\(host)&sz=32") else {
            return nil
        }

        do {
            let (data, _) = try await session.data(from: faviconURL)
            faviconCache[host] = data
            return data
        } catch {
            return nil
        }
    }

    func fetchPageTitle(for url: URL) async -> String? {
        let key = url.absoluteString
        if let cached = titleCache[key] { return cached }

        do {
            let (data, _) = try await session.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }

            let pattern = try NSRegularExpression(pattern: "<title[^>]*>(.*?)</title>", options: [.caseInsensitive, .dotMatchesLineSeparators])
            let range = NSRange(html.startIndex..., in: html)
            guard let match = pattern.firstMatch(in: html, range: range),
                  let titleRange = Range(match.range(at: 1), in: html) else {
                return nil
            }

            let title = String(html[titleRange])
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<")
                .replacingOccurrences(of: "&gt;", with: ">")
                .replacingOccurrences(of: "&#39;", with: "'")
                .replacingOccurrences(of: "&quot;", with: "\"")

            guard !title.isEmpty else { return nil }
            titleCache[key] = title
            return title
        } catch {
            return nil
        }
    }
}
