# CLAUDE.md

## Build
When verifying, First 'pkill jetgrind', then launch the app via 'swift run JetGrind' in the terminal, background the process and ask the user to verify changes.

## Architecture

Menu bar todo app using SwiftUI (macOS 15+, Swift 6.0).

- **JetGrindApp.swift** - Entry point using `MenuBarExtra` with `.window` style
- **TodoStore** - `@Observable` class managing state with UserDefaults persistence
- **Views** - TodoListView contains AddTodoView and list of TodoRowView items

Data flows through a single `TodoStore` instance passed from app to views via `@Bindable`.

## Known Fixes

**Keyboard delete on MacBook**: `.onKeyPress(keys: [.delete, .deleteForward])` doesn't work for MacBook keyboards—their "Delete" key sends backspace (`\u{7F}`), not forward-delete. Add a catch-all `.onKeyPress` handler checking `keyPress.key.character == "\u{7F}"`.

**Key capture in MenuBarExtra apps**: `NSViewRepresentable` with `keyDown:` doesn't work—SwiftUI's Form steals first responder, and `performKeyEquivalent:` preempts `keyDown:` for modifier combos. `NSApp.activate` is ignored because `MenuBarExtra` sets `.accessory` activation policy. Fix: use `NSEvent.addLocalMonitorForEvents(matching: .keyDown)` with a local-only monitor. Temporarily switch to `.regular` activation policy before `NSApp.activate(ignoringOtherApps: true)`, then revert to `.accessory` when done. This pulls focus so the local monitor receives and consumes keystrokes. See `HotKeyRecorderView.swift`.

## Debugging

**Start from the difference**: When a bug affects some items but not others (e.g., 2 of 3 buttons clip but the third doesn't), compare the affected vs unaffected items directly. The fix is in what differs between them, not in shared ancestors.

## Communication

Keep summaries very succinct.

## Planning

When planning always use the /brainstorming skill.
