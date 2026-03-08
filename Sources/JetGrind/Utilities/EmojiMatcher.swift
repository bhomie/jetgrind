import Foundation

enum EmojiMatcher {
    struct Category {
        let emojis: [String]
        let keywords: [String]
    }

    static let categories: [Category] = [
        Category(emojis: ["🛒", "🛍️"], keywords: ["buy", "shop", "grocery", "groceries", "store", "order", "purchase"]),
        Category(emojis: ["💻", "⌨️", "🐛"], keywords: ["code", "bug", "deploy", "build", "fix", "debug", "refactor", "commit", "merge", "pr", "review"]),
        Category(emojis: ["🍳", "🍕", "🥗"], keywords: ["cook", "recipe", "dinner", "lunch", "breakfast", "meal", "food", "eat", "bake"]),
        Category(emojis: ["🏋️", "🏃", "💪"], keywords: ["gym", "workout", "exercise", "run", "yoga", "fitness", "stretch", "walk", "hike"]),
        Category(emojis: ["🏠", "🔧", "🧹"], keywords: ["home", "house", "apartment", "rent", "move", "furniture", "repair", "mow", "lawn"]),
        Category(emojis: ["✈️", "🗺️", "🧳"], keywords: ["travel", "flight", "trip", "vacation", "hotel", "book", "pack", "passport"]),
        Category(emojis: ["💰", "🏦", "💳"], keywords: ["pay", "bill", "bank", "money", "budget", "invest", "tax", "finance", "invoice"]),
        Category(emojis: ["💊", "🏥", "🩺"], keywords: ["doctor", "dentist", "health", "medicine", "appointment", "therapy", "prescription", "checkup"]),
        Category(emojis: ["👋", "🎉", "🍻"], keywords: ["meet", "party", "dinner", "hangout", "friend", "date", "call", "catch up", "birthday"]),
        Category(emojis: ["📚", "🎓", "✏️"], keywords: ["study", "learn", "read", "course", "class", "homework", "research", "tutorial", "book"]),
        Category(emojis: ["🎵", "🎸", "🎧"], keywords: ["music", "guitar", "piano", "practice", "song", "playlist", "concert", "listen"]),
        Category(emojis: ["🎨", "🖌️", "📐"], keywords: ["design", "draw", "paint", "sketch", "art", "illustrate", "figma", "mockup"]),
        Category(emojis: ["🐶", "🐱", "🐾"], keywords: ["dog", "cat", "pet", "vet", "walk dog", "feed", "groom"]),
        Category(emojis: ["🧹", "🧺", "🧽"], keywords: ["clean", "laundry", "vacuum", "dishes", "tidy", "organize", "declutter", "wash"]),
        Category(emojis: ["🎮", "🕹️"], keywords: ["game", "gaming", "play", "steam", "xbox", "playstation", "nintendo"]),
        Category(emojis: ["📧", "📱", "💬"], keywords: ["email", "text", "message", "reply", "respond", "send", "slack", "dm"]),
        Category(emojis: ["📊", "📋", "🤝"], keywords: ["meeting", "presentation", "report", "standup", "sync", "agenda", "review", "plan"]),
        Category(emojis: ["✍️", "📝", "📖"], keywords: ["write", "blog", "essay", "draft", "edit", "journal", "notes", "document"]),
        Category(emojis: ["📦", "📬", "🚚"], keywords: ["ship", "package", "deliver", "mail", "return", "pickup", "post office"]),
    ]

    /// Returns all relevant emojis for a title (merged from matching categories, deduplicated)
    static func matchedEmojis(for title: String) -> [String] {
        let lowered = title.lowercased()
        var matched: [String] = []
        var seen = Set<String>()

        for category in categories {
            let hits = category.keywords.contains { keyword in
                lowered.containsWord(keyword)
            }
            if hits {
                for emoji in category.emojis where !seen.contains(emoji) {
                    seen.insert(emoji)
                    matched.append(emoji)
                }
            }
        }
        return matched
    }

    /// Returns the best single emoji for a title, or random fallback from general pool
    static func bestEmoji(for title: String) -> String {
        let matched = matchedEmojis(for: title)
        if let first = matched.first { return first }
        return EmojiPool.random()
    }

    /// Cycles through relevant emojis first, then falls back to the general pool
    static func nextEmoji(for title: String, current: String?) -> String {
        let matched = matchedEmojis(for: title)

        if !matched.isEmpty, let current {
            if let idx = matched.firstIndex(of: current), idx + 1 < matched.count {
                return matched[idx + 1]
            }
        }

        // Fall back to general pool, excluding current
        return EmojiPool.randomExcluding(current ?? "")
    }
}

private let precompiledKeywordPatterns: [String: NSRegularExpression] = {
    var dict = [String: NSRegularExpression]()
    for category in EmojiMatcher.categories {
        for keyword in category.keywords where dict[keyword] == nil {
            let pattern = "\\b\(NSRegularExpression.escapedPattern(for: keyword))\\b"
            // swiftlint:disable:next force_try
            dict[keyword] = try! NSRegularExpression(pattern: pattern, options: .caseInsensitive)
        }
    }
    return dict
}()

private extension String {
    /// Checks if the string contains the given word, matching at word boundaries (case-insensitive).
    /// Supports multi-word keywords like "catch up".
    func containsWord(_ word: String) -> Bool {
        guard let regex = precompiledKeywordPatterns[word] else { return false }
        let range = NSRange(startIndex..., in: self)
        return regex.firstMatch(in: self, range: range) != nil
    }
}
