# Font Token Consolidation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace 21 font tokens with 5 semantic tokens (`caption`, `body`, `title`, `display`, `hero`).

**Architecture:** Rewrite `Theme.Font` enum with 5 static properties. Update all call sites via find-and-replace per old token name. No behavioral changes — only token names and some sizes shift by 1-2pt.

**Tech Stack:** SwiftUI, macOS 15+

---

### Task 1: Replace Theme.Font enum

**Files:**
- Modify: `Sources/JetGrind/Themes/Theme.swift:13-56`

**Step 1: Replace the Font enum**

Replace the entire `enum Font { ... }` block (lines 13-56) with:

```swift
    enum Font {
        static let caption: CGFloat = 10
        static let body: CGFloat = 12
        static let title: CGFloat = 16
        static let display: CGFloat = 20
        static let hero: CGFloat = 48
    }
```

**Step 2: Build to see all broken references**

Run: `swift build 2>&1 | head -40`
Expected: Multiple errors for removed token names — this confirms all call sites that need updating.

---

### Task 2: Update TodoRowView.swift

**Files:**
- Modify: `Sources/JetGrind/Views/TodoRowView.swift`

**Step 1: Apply replacements**

| Old token | New token | Lines |
|---|---|---|
| `Theme.Font.emojiLarge` | `Theme.Font.display` | 258 |
| `Theme.Font.titleMedium` | `Theme.Font.title` | 278, 292, 311 |
| `Theme.Font.description` | `Theme.Font.body` | 335, 355, 363 |
| `Theme.Font.iconSmall` | `Theme.Font.caption` | 390 |
| `Theme.Font.actionIcon` | `Theme.Font.body` | 449 |
| `Theme.Font.actionLabel` | `Theme.Font.caption` | 451 |
| `Theme.Font.timestamp` | `Theme.Font.body` | 482 |

`Theme.Font.body` on lines 388 stays as-is (already named `body`).

---

### Task 3: Update AddTodoView.swift

**Files:**
- Modify: `Sources/JetGrind/Views/AddTodoView.swift`

**Step 1: Apply replacements**

| Old token | New token | Lines |
|---|---|---|
| `Theme.Font.iconLarge` | `Theme.Font.display` | 90, 91 |
| `Theme.Font.actionIcon` | `Theme.Font.body` | 120 |
| `Theme.Font.bodyMedium` | `Theme.Font.body` | 123, 127 |

`Theme.Font.body` on line 51 stays as-is.

---

### Task 4: Update CompletedTabView.swift

**Files:**
- Modify: `Sources/JetGrind/Views/CompletedTabView.swift`

**Step 1: Apply replacements**

| Old token | New token | Lines |
|---|---|---|
| `Theme.Font.emoji` | `Theme.Font.title` | 111 |
| `Theme.Font.icon` | `Theme.Font.title` | 114 |
| `Theme.Font.bodyMedium` | `Theme.Font.body` | 119 |

`Theme.Font.body` on line 127 stays as-is.

---

### Task 5: Update TodoListView.swift

**Files:**
- Modify: `Sources/JetGrind/Views/TodoListView.swift`

**Step 1: Apply replacements**

| Old token | New token | Lines |
|---|---|---|
| `Theme.Font.emptyStateIcon` | `Theme.Font.hero` | 270, 301 |
| `Theme.Font.emptyStateTitle` | `Theme.Font.body` | 275, 307 |
| `Theme.Font.emptyStateSubtitle` | `Theme.Font.caption` | 281 |

---

### Task 6: Update remaining views

**Files:**
- Modify: `Sources/JetGrind/Views/HotkeyHintsView.swift`
- Modify: `Sources/JetGrind/Views/HotKeyRecorderView.swift`
- Modify: `Sources/JetGrind/Views/LinkPillView.swift`
- Modify: `Sources/JetGrind/Views/PillTextView.swift`

**Step 1: Apply replacements**

| File | Old token | New token |
|---|---|---|
| `HotkeyHintsView.swift:18` | `Theme.Font.hotkeyHint` | `Theme.Font.caption` |
| `HotKeyRecorderView.swift:20` | `Theme.Font.hotkeyRecorder` | `Theme.Font.body` |
| `LinkPillView.swift:21` | `Theme.Font.linkPillLabel` | `Theme.Font.caption` |
| `LinkPillView.swift:25,51,55` | `Theme.Font.linkPillFavicon` | `Theme.Font.body` |
| `PillTextView.swift:125` | `Theme.Font.titleMedium` | `Theme.Font.title` |

---

### Task 7: Build, verify, commit

**Step 1: Build**

Run: `swift build 2>&1`
Expected: `Build complete!` with zero errors.

**Step 2: Launch and verify**

Run: `pkill -f JetGrind; swift run JetGrind`
Ask user to verify visuals.

**Step 3: Commit**

```bash
git add Sources/JetGrind/Themes/Theme.swift \
      Sources/JetGrind/Views/TodoRowView.swift \
      Sources/JetGrind/Views/AddTodoView.swift \
      Sources/JetGrind/Views/CompletedTabView.swift \
      Sources/JetGrind/Views/TodoListView.swift \
      Sources/JetGrind/Views/HotkeyHintsView.swift \
      Sources/JetGrind/Views/HotKeyRecorderView.swift \
      Sources/JetGrind/Views/LinkPillView.swift \
      Sources/JetGrind/Views/PillTextView.swift
git commit -m "Consolidate 21 font tokens into 5 semantic tokens (caption/body/title/display/hero)"
```
