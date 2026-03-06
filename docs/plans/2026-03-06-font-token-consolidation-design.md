# Font Token Consolidation

## Goal

Replace 21 specific font tokens with 5 semantic tokens using a typographic scale.

## Token Map

| Token | Size | Replaces |
|---|---|---|
| `caption` | 10 | `iconSmall` (10), `hotkeyHint` (11), `actionLabel` (11), `linkPillLabel` (11), `emptyStateSubtitle` (11) |
| `body` | 12 | `body` (12), `bodyMedium` (12), `bodySemibold` (12), `timestamp` (12), `actionIcon` (12), `linkPillFavicon` (12), `description` (13), `hotkeyRecorder` (13), `emptyStateTitle` (13) |
| `title` | 16 | `title` (16), `titleMedium` (16), `icon` (16), `emoji` (16) |
| `display` | 20 | `emojiLarge` (20), `iconLarge` (18) |
| `hero` | 48 | `emptyStateIcon` (48) |

## Size Changes

- 11 -> 10: hotkey hints, action labels, link pill labels, empty state subtitle (-1pt)
- 13 -> 12: description text, hotkey recorder, empty state headline (-1pt)
- 18 -> 20: add button icon (+2pt)

## Rules

- Weights are applied at call sites, not in the token
- All usages reference `Theme.Font.<token>`

## Files to Update

- `Sources/JetGrind/Themes/Theme.swift` — replace 21 tokens with 5
- `Sources/JetGrind/Views/TodoRowView.swift`
- `Sources/JetGrind/Views/AddTodoView.swift`
- `Sources/JetGrind/Views/CompletedTabView.swift`
- `Sources/JetGrind/Views/TodoListView.swift`
- `Sources/JetGrind/Views/HotkeyHintsView.swift`
- `Sources/JetGrind/Views/HotKeyRecorderView.swift`
- `Sources/JetGrind/Views/LinkPillView.swift`
- `Sources/JetGrind/Views/PillTextView.swift`
