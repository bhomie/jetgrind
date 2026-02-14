import Foundation

struct LinkItem: Identifiable, Codable, Hashable {
    let id: UUID
    let url: URL
    var displayTitle: String
    var faviconData: Data?
    var isTitleFetched: Bool

    init(id: UUID = UUID(), url: URL, displayTitle: String? = nil, faviconData: Data? = nil, isTitleFetched: Bool = false) {
        self.id = id
        self.url = url
        self.displayTitle = displayTitle ?? url.host() ?? url.absoluteString
        self.faviconData = faviconData
        self.isTitleFetched = isTitleFetched
    }
}
