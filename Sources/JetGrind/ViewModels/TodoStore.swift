import Foundation

@MainActor
@Observable
final class TodoStore {
    private static let storageKey = "jetgrind.todos"
    private static let migrationKey = "jetgrind.migratedToMarkerFormat"

    var items: [TodoItem] = []

    init() {
        load()
    }

    func add(title: String) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let result = TodoTextSplitter.split(trimmed)
        let item = TodoItem(title: result.title, description: result.description, links: result.links)

        // If input was a single URL, fetch page title async
        let isSingleURL = URLDetector.isSingleURL(trimmed)

        items.insert(item, at: 0)
        save()

        // Fire-and-forget async fetches
        let itemId = item.id
        if isSingleURL, let url = result.links.first?.url {
            Task {
                await self.fetchPageTitleForItem(id: itemId, url: url)
            }
        }
        for (linkIndex, link) in result.links.enumerated() {
            Task {
                await self.fetchFaviconForLink(itemId: itemId, linkIndex: linkIndex, url: link.url)
            }
        }
    }

    func toggle(id: UUID) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].isCompleted.toggle()
        save()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        save()
    }

    func updateTitle(id: UUID, newTitle: String) {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].title = trimmed
        save()
    }

    func updateTitleAndDescription(id: UUID, newTitle: String, newDescription: String?) {
        let trimmedTitle = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty,
              let index = items.firstIndex(where: { $0.id == id }) else { return }

        items[index].title = trimmedTitle
        let trimmedDesc = newDescription?.trimmingCharacters(in: .whitespacesAndNewlines)
        items[index].description = (trimmedDesc?.isEmpty ?? true) ? nil : trimmedDesc

        // Re-sync links from combined text
        let combinedText = trimmedTitle + " " + (trimmedDesc ?? "")
        syncLinks(for: index, from: combinedText)
        save()
    }

    func updateTitleDescriptionAndLinks(id: UUID, title: String, description: String?, links: [LinkItem]) {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty,
              let index = items.firstIndex(where: { $0.id == id }) else { return }

        items[index].title = trimmedTitle
        let trimmedDesc = description?.trimmingCharacters(in: .whitespacesAndNewlines)
        items[index].description = (trimmedDesc?.isEmpty ?? true) ? nil : trimmedDesc
        items[index].links = links
        save()

        // Fetch favicons for any new links missing data
        let itemId = items[index].id
        for (linkIndex, link) in links.enumerated() where link.faviconData == nil {
            Task {
                await self.fetchFaviconForLink(itemId: itemId, linkIndex: linkIndex, url: link.url)
            }
        }
    }

    func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([TodoItem].self, from: data) else {
            return
        }
        items = decoded
        migrateToMarkerFormat()
    }

    // MARK: - Migration

    private func migrateToMarkerFormat() {
        guard !UserDefaults.standard.bool(forKey: Self.migrationKey) else { return }

        var didMigrate = false
        for i in items.indices {
            // Migrate title
            let titleResult = TextPillConverter.migrateRawURLs(text: items[i].title, existingLinks: items[i].links)
            if titleResult.text != items[i].title {
                items[i].title = titleResult.text
                items[i].links = titleResult.links
                didMigrate = true
            }

            // Migrate description
            if let desc = items[i].description {
                let descResult = TextPillConverter.migrateRawURLs(text: desc, existingLinks: items[i].links)
                if descResult.text != desc {
                    items[i].description = descResult.text
                    items[i].links = descResult.links
                    didMigrate = true
                }
            }
        }

        UserDefaults.standard.set(true, forKey: Self.migrationKey)
        if didMigrate { save() }
    }

    // MARK: - Link Syncing

    private func syncLinks(for index: Int, from text: String) {
        let newURLs = URLDetector.extractURLs(from: text)
        let existingByURL = Dictionary(uniqueKeysWithValues: items[index].links.map { ($0.url, $0) })

        var synced: [LinkItem] = []
        for url in newURLs {
            if let existing = existingByURL[url] {
                synced.append(existing)
            } else {
                let link = LinkItem(url: url)
                synced.append(link)
                // Fetch favicon for new link
                let itemId = items[index].id
                let linkIndex = synced.count - 1
                Task {
                    await self.fetchFaviconForLink(itemId: itemId, linkIndex: linkIndex, url: url)
                }
            }
        }
        items[index].links = synced
    }

    // MARK: - Metadata Fetching

    private func fetchPageTitleForItem(id: UUID, url: URL) async {
        guard let title = await LinkMetadataFetcher.shared.fetchPageTitle(for: url) else { return }
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        items[index].title = title
        save()
    }

    private func fetchFaviconForLink(itemId: UUID, linkIndex: Int, url: URL) async {
        guard let data = await LinkMetadataFetcher.shared.fetchFavicon(for: url) else { return }
        guard let itemIndex = items.firstIndex(where: { $0.id == itemId }),
              linkIndex < items[itemIndex].links.count,
              items[itemIndex].links[linkIndex].url == url else { return }
        items[itemIndex].links[linkIndex].faviconData = data
        save()
    }
}
