import Foundation

enum EmojiPool {
    private static let emojis = [
        "🚀", "✨", "🔥", "💡", "🎯",
        "⚡", "🌈", "🍀", "🎨", "💎",
        "🌸", "🎵", "🦋", "🍕", "🏄",
        "🌊", "🎲", "🧩", "🛸", "🌻",
    ]

    static func random() -> String {
        emojis.randomElement()!
    }

    static func randomExcluding(_ current: String) -> String {
        let filtered = emojis.filter { $0 != current }
        return filtered.randomElement() ?? current
    }
}
