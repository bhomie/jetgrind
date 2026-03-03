# Keyboard Scroll-to-Focus with Edge Blur

## Problem

When navigating the todo list with arrow keys, focus moves to off-screen items but the scroll position doesn't follow. The user loses sight of the focused item.

## Approach

ScrollViewReader + `.scrollTo()` triggered by `.onChange(of: focus)` with direction-aware anchoring.

## Architecture

Changes confined to **TodoListView.swift** and **CompletedTabView.swift**. No new files or types.

Wrap existing `LazyVStack` content in `ScrollViewReader`. Add `.onChange(of: focus)` to detect keyboard-driven focus changes and call `proxy.scrollTo(id, anchor:)` with the focused item's ID and a direction-appropriate anchor.

```
ScrollView {
    ScrollViewReader { proxy in
        LazyVStack(spacing: 4) { ... }
        .onChange(of: focus) { oldFocus, newFocus in
            // determine direction, call scrollTo
        }
    }
}
```

## Scroll Behavior

**Direction detection:** Map focus cases to indices (`.input` = -1, `.task(id)` = array position). New index > old index = scrolling down.

**Anchor offsets:**
- Down: `UnitPoint(x: 0.5, y: 0.85)` — focused item at 85%, 15% viewport for next-item hint
- Up: `UnitPoint(x: 0.5, y: 0.15)` — focused item at 15%, room above for context
- To input: `UnitPoint(x: 0.5, y: 0.0)` — snap to top

**Animation:** `withAnimation(.spring(response: 0.3, dampingFraction: 0.8))` — matches existing app timing.

**Mouse scrolling:** Unaffected — `scrollTo` only fires inside `.onChange(of: focus)`, and mouse interactions don't change `@FocusState`.

## Edge Fades with Progressive Blur

Both top and bottom edges get a fade overlay combining opacity gradient + stacked blur strips.

**Structure per edge:**
- 3-4 thin rectangles stacked from the edge inward
- Each strip has increasing `.blur()` radius (e.g. 0.5, 2, 5, 8pt) and decreasing opacity
- All overlays use `.allowsHitTesting(false)`

**Top fade:** Conditional — only visible when scroll offset > 0 (content scrolled down). Detected via `.onScrollGeometryChange(for: CGFloat.self)`.

**Bottom fade:** Replaces the current `.mask(LinearGradient(...))` with the same stacked-blur-plus-opacity overlay for consistency.

**Fade zone height:** ~40-50pt per edge.

Applies to both TodoListView and CompletedTabView.

## Edge Cases

- **First item from input:** Scroll to top, no hint above needed
- **Last item:** Anchor at 85% still works; nothing below to hint, which is fine
- **Action mode (edit/delete):** Same row — no scroll triggered
- **Edit mode:** Same row context — no scroll triggered
- **CompletedTabView:** Independent ScrollViewReader + blur overlay
- **Few items (no scroll):** `scrollTo` is a no-op when content fits viewport
