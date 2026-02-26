# AGENTS.md

## Cursor Cloud specific instructions

### Environment

JetGrind is a **macOS-only** menu bar app (SwiftUI + AppKit, targets `.macOS(.v26)`). The Cloud VM runs Linux, so:

- **Full GUI build/run is not possible** on Linux — `AppKit` and `SwiftUI` frameworks are macOS-only.
- The Swift 6.2 toolchain is installed at `/opt/swift/usr/bin` and on `PATH` via `~/.bashrc`.
- SPM dependency resolution (`swift package resolve`) works fully on Linux.
- The HotKey dependency compiles on Linux; the JetGrind target does not (expected).

### Available commands on Linux

| Command | Works? | Notes |
|---|---|---|
| `swift package resolve` | Yes | Fetches/updates SPM dependencies |
| `swift package dump-package` | Yes | Validates `Package.swift` manifest |
| `swift package describe` | Yes | Shows targets, products, dependencies |
| `swift build` | Partial | HotKey dep compiles; JetGrind fails on `import AppKit` (expected) |
| `swift-format lint --recursive Sources/` | Yes | Linting (bundled with toolchain); project uses tabs, tool defaults to spaces — indentation warnings are expected |
| `swift run JetGrind` | No | Requires macOS with GUI |

### Build & run (macOS only)

See `CLAUDE.md` for canonical build commands: `swift build` / `swift run JetGrind`.

### No test targets

The project has no `Tests/` directory or test targets in `Package.swift`. Platform-independent logic (models, utilities) can be verified by compiling standalone Swift scripts on Linux.
