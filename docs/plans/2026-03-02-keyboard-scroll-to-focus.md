# Keyboard Scroll-to-Focus with Edge Blur Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** When keyboard-navigating the todo list, scroll to keep the focused item visible with a gentle spring animation, and add progressive blur+opacity fades at both scroll edges.

**Architecture:** Wrap `LazyVStack` in `ScrollViewReader`, trigger `scrollTo` on `@FocusState` changes with direction-aware anchors. Replace the existing bottom gradient mask with a dynamic two-sided mask, and overlay stacked material blur strips at both edges. Track scroll offset via `.onScrollGeometryChange` for conditional top fade.

**Tech Stack:** SwiftUI (macOS 15+), ScrollViewReader, .ultraThinMaterial

---

### Task 1: Add ScrollViewReader + scrollTo to TodoListView

**Files:**
- Modify: `Sources/JetGrind/Views/TodoListView.swift:58-80`

**Step 1: Wrap LazyVStack in ScrollViewReader**

Inside the existing `ScrollView` (line 58), wrap the `LazyVStack` in a `ScrollViewReader`:

```swift
ScrollView {
    ScrollViewReader { proxy in
        LazyVStack(spacing: 4) {
            ForEach(Array(incompleteItems.enumerated()), id: \.element.id) { index, item in
                let prevId = index > 0 ? incompleteItems[index - 1].id : nil
                let nextId = index < incompleteItems.count - 1 ? incompleteItems[index + 1].id : nil

                todoRow(item: item, previousTaskId: prevId, nextTaskId: nextId, rowIndex: index)
            }
        }
        .padding(.horizontal, 8)
        .onChange(of: focus) { oldFocus, newFocus in
            guard let newFocus else { return }

            switch newFocus {
            case .task(let id):
                let newIndex = incompleteItems.firstIndex(where: { $0.id == id }) ?? 0
                let oldIndex: Int
                switch oldFocus {
                case .task(let oldId):
                    oldIndex = incompleteItems.firstIndex(where: { $0.id == oldId }) ?? 0
                case .input:
                    oldIndex = -1
                default:
                    return // action/edit focus on same row — no scroll
                }
                if oldIndex == newIndex { return }
                let anchor: UnitPoint = newIndex > oldIndex
                    ? UnitPoint(x: 0.5, y: 0.85)
                    : UnitPoint(x: 0.5, y: 0.15)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    proxy.scrollTo(id, anchor: anchor)
                }
            default:
                break
            }
        }
    }
}
```

Note: This is a NEW `.onChange(of: focus)` inside `ScrollViewReader`. The existing one at line 125 (which handles expand/collapse) stays untouched.

**Step 2: Build and verify**

Run: `pkill -f JetGrind; swift run JetGrind`

Verify: Add 8+ tasks so the list overflows. Use arrow keys to navigate past the bottom — the list should smoothly scroll to reveal the focused item. Navigate back up — same behavior. Mouse scrolling should still work independently.

**Step 3: Commit**

```bash
git add Sources/JetGrind/Views/TodoListView.swift
git commit -m "Add keyboard scroll-to-focus in TodoListView"
```

---

### Task 2: Add ScrollViewReader + scrollTo to CompletedTabView

**Files:**
- Modify: `Sources/JetGrind/Views/CompletedTabView.swift:13-35`

**Step 1: Wrap LazyVStack in ScrollViewReader**

Same pattern as Task 1. Inside the `ScrollView` (line 14), wrap the `LazyVStack`:

```swift
ScrollView {
    ScrollViewReader { proxy in
        LazyVStack(spacing: 4) {
            ForEach(Array(completedItems.enumerated()), id: \.element.id) { index, item in
                let prevId = index > 0 ? completedItems[index - 1].id : nil
                let nextId = index < completedItems.count - 1 ? completedItems[index + 1].id : nil
                completedRow(item: item, previousId: prevId, nextId: nextId, isFirst: index == 0, rowIndex: index)
            }
        }
        .padding(.horizontal, 8)
        .onChange(of: focus.wrappedValue) { oldFocus, newFocus in
            guard let newFocus else { return }

            switch newFocus {
            case .completedTask(let id):
                let newIndex = completedItems.firstIndex(where: { $0.id == id }) ?? 0
                let oldIndex: Int
                if case .completedTask(let oldId) = oldFocus {
                    oldIndex = completedItems.firstIndex(where: { $0.id == oldId }) ?? 0
                } else {
                    oldIndex = -1
                }
                if oldIndex == newIndex { return }
                let anchor: UnitPoint = newIndex > oldIndex
                    ? UnitPoint(x: 0.5, y: 0.85)
                    : UnitPoint(x: 0.5, y: 0.15)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    proxy.scrollTo(id, anchor: anchor)
                }
            default:
                break
            }
        }
    }
}
```

Note: CompletedTabView uses `focus.wrappedValue` (it receives a `FocusState<TodoFocus?>.Binding`, not `@FocusState`), so `.onChange(of: focus.wrappedValue)`.

**Step 2: Build and verify**

Run: `pkill -f JetGrind; swift run JetGrind`

Verify: Complete 8+ tasks, open completed view, arrow-key through them — list scrolls to keep focused item visible.

**Step 3: Commit**

```bash
git add Sources/JetGrind/Views/CompletedTabView.swift
git commit -m "Add keyboard scroll-to-focus in CompletedTabView"
```

---

### Task 3: Add edge blur overlays to TodoListView

**Files:**
- Modify: `Sources/JetGrind/Views/TodoListView.swift:58-80`

**Step 1: Add scroll offset state**

Add a new `@State` to TodoListView (near the other `@State` declarations around line 7):

```swift
@State private var isScrolledFromTop = false
```

**Step 2: Add scroll offset detection**

Add `.onScrollGeometryChange` to the `ScrollView` (after `.scrollIndicators(.hidden)`):

```swift
.onScrollGeometryChange(for: Bool.self) { geometry in
    geometry.contentOffset.y > 5
} action: { _, isScrolled in
    withAnimation(.easeInOut(duration: 0.2)) {
        isScrolledFromTop = isScrolled
    }
}
```

**Step 3: Replace gradient mask with two-sided dynamic mask**

Replace the existing `.mask(LinearGradient(...))` (lines 70-80) with:

```swift
.mask(
    LinearGradient(
        stops: [
            .init(color: isScrolledFromTop ? .clear : .black, location: 0),
            .init(color: .black, location: isScrolledFromTop ? 0.12 : 0),
            .init(color: .black, location: 0.7),
            .init(color: .clear, location: 1.0)
        ],
        startPoint: .top,
        endPoint: .bottom
    )
    .animation(.easeInOut(duration: 0.2), value: isScrolledFromTop)
)
```

**Step 4: Add blur overlays**

After the `.mask(...)`, add overlays for both edges:

```swift
.overlay(alignment: .bottom) {
    VStack(spacing: 0) {
        Rectangle().fill(.ultraThinMaterial).frame(height: 12).opacity(0.15)
        Rectangle().fill(.ultraThinMaterial).frame(height: 12).opacity(0.4)
        Rectangle().fill(.ultraThinMaterial).frame(height: 12).opacity(0.7)
        Rectangle().fill(.ultraThinMaterial).frame(height: 12).opacity(1.0)
    }
    .allowsHitTesting(false)
}
.overlay(alignment: .top) {
    if isScrolledFromTop {
        VStack(spacing: 0) {
            Rectangle().fill(.ultraThinMaterial).frame(height: 12).opacity(1.0)
            Rectangle().fill(.ultraThinMaterial).frame(height: 12).opacity(0.7)
            Rectangle().fill(.ultraThinMaterial).frame(height: 12).opacity(0.4)
            Rectangle().fill(.ultraThinMaterial).frame(height: 12).opacity(0.15)
        }
        .transition(.opacity)
        .allowsHitTesting(false)
    }
}
```

Note: Bottom strips go from light → heavy (top to bottom toward edge). Top strips go from heavy → light (top edge outward to content). The top overlay only appears when scrolled.

**Step 5: Build and verify**

Run: `pkill -f JetGrind; swift run JetGrind`

Verify:
- Bottom of list has progressive blur + opacity fade
- Scroll down — top fade + blur appears
- Scroll back to top — top fade disappears
- Mouse scrolling still works normally
- Keyboard navigation triggers both scroll AND the blur is visible at edges

**Step 6: Commit**

```bash
git add Sources/JetGrind/Views/TodoListView.swift
git commit -m "Add progressive blur edge fades to TodoListView"
```

---

### Task 4: Add edge blur overlays to CompletedTabView

**Files:**
- Modify: `Sources/JetGrind/Views/CompletedTabView.swift:13-35`

**Step 1: Add scroll offset state**

Add to CompletedTabView:

```swift
@State private var isScrolledFromTop = false
```

**Step 2: Apply same changes as Task 3**

Replace the existing `.mask(LinearGradient(...))` and add `.onScrollGeometryChange`, `.mask(...)` with dynamic stops, and both `.overlay(alignment:)` blocks — identical to Task 3.

**Step 3: Build and verify**

Run: `pkill -f JetGrind; swift run JetGrind`

Verify: Complete 8+ tasks, open completed view — same blur+fade behavior at both edges.

**Step 4: Commit**

```bash
git add Sources/JetGrind/Views/CompletedTabView.swift
git commit -m "Add progressive blur edge fades to CompletedTabView"
```

---

### Task 5: Visual tuning pass

**Files:**
- Modify: `Sources/JetGrind/Views/TodoListView.swift`
- Modify: `Sources/JetGrind/Views/CompletedTabView.swift`

**Step 1: Build and do a full manual test**

Run: `pkill -f JetGrind; swift run JetGrind`

Test checklist:
- [ ] Arrow-key down past visible area — smooth scroll, focused item visible
- [ ] Arrow-key up past visible area — smooth scroll, focused item visible
- [ ] Down from input to first item — no unnecessary scroll
- [ ] Mouse scroll — no interference from keyboard scroll logic
- [ ] Bottom blur fade looks natural, not too heavy
- [ ] Top blur fade appears/disappears smoothly on scroll
- [ ] Completed view has same behavior
- [ ] Few items (no overflow) — no visual artifacts

**Step 2: Tune values if needed**

Adjustable values and what they control:
- Scroll anchor Y (0.85/0.15) — how much "hint" of next item is shown
- Blur strip height (12pt each) — height of each blur band
- Blur strip opacities (0.15, 0.4, 0.7, 1.0) — how aggressive the blur taper is
- Mask gradient stop (0.12 for top, 0.7/1.0 for bottom) — where opacity fade starts/ends
- Scroll offset threshold (5pt) — when top fade appears
- Material type (.ultraThinMaterial) — try .thinMaterial if blur is too subtle

**Step 3: Commit final tuning**

```bash
git add Sources/JetGrind/Views/TodoListView.swift Sources/JetGrind/Views/CompletedTabView.swift
git commit -m "Tune edge blur and scroll anchor values"
```
