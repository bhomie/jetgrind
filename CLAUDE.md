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

## Communication

Keep summaries very succinct.
