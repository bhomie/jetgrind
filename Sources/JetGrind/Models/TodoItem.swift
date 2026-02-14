import Foundation

struct TodoItem: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String?
    var links: [LinkItem]
    var isCompleted: Bool
    let createdAt: Date

    init(id: UUID = UUID(), title: String, description: String? = nil, links: [LinkItem] = [], isCompleted: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.links = links
        self.isCompleted = isCompleted
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        links = try container.decodeIfPresent([LinkItem].self, forKey: .links) ?? []
        isCompleted = try container.decode(Bool.self, forKey: .isCompleted)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
}
