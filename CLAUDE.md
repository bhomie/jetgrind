# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build

```bash
swift build
swift run JetGrind  # launches menu bar app
```

## Architecture

Menu bar todo app using SwiftUI (macOS 15+, Swift 6.0).

- **JetGrindApp.swift** - Entry point using `MenuBarExtra` with `.window` style
- **TodoStore** - `@Observable` class managing state with UserDefaults persistence
- **Views** - TodoListView contains AddTodoView and list of TodoRowView items

Data flows through a single `TodoStore` instance passed from app to views via `@Bindable`.

## Known Fixes

**Keyboard delete on MacBook**: `.onKeyPress(keys: [.delete, .deleteForward])` doesn't work for MacBook keyboards—their "Delete" key sends backspace (`\u{7F}`), not forward-delete. Add a catch-all `.onKeyPress` handler checking `keyPress.key.character == "\u{7F}"`.

**Key capture in MenuBarExtra apps**: `NSViewRepresentable` with `keyDown:` doesn't work—SwiftUI's Form steals first responder, and `performKeyEquivalent:` preempts `keyDown:` for modifier combos. `NSApp.activate` is ignored because `MenuBarExtra` sets `.accessory` activation policy. Fix: use `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` with a local-only monitor. Temporarily switch to `.regular` activation policy before `NSApp.activate(ignoringOtherApps: true)`, then revert to `.accessory` when done. This pulls focus so the local monitor receives and consumes keystrokes. See `HotKeyRecorderView.swift`.

## Communication

Keep summaries very succinct.

## Planning

When planning implementation, always ask follow-up questions to understand intent and bring clarity to the vision before proposing an approach. Don't assume—ask.
