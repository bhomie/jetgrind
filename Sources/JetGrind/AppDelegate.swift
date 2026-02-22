import AppKit
import SwiftUI
import HotKey

extension Notification.Name {
    static let focusTaskInput = Notification.Name("focusTaskInput")
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    let settingsStore = SettingsStore()
    let store = TodoStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let mainBundle = CFBundleGetMainBundle()
        if let infoDict = CFBundleGetInfoDictionary(mainBundle) {
            let mutableDict = infoDict as! CFMutableDictionary  // CF info dict is always mutable
            CFDictionarySetValue(
                mutableDict,
                Unmanaged.passUnretained("CFBundleIdentifier" as CFString).toOpaque(),
                Unmanaged.passUnretained("com.jetgrind.app" as CFString).toOpaque()
            )
        }
        setupStatusItem()
        setupPopover()
        setupHotKey()
        setupStoreObservation()
        updateStatusItemBadge()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "JetGrind")
            button.imagePosition = .imageLeading
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: TodoListView(store: store))
    }

    private func setupHotKey() {
        // HotKey registration is handled by SettingsStore
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleShowPopoverAndFocus),
            name: .showPopoverAndFocus,
            object: nil
        )
    }

    private func setupStoreObservation() {
        observeStoreChanges()
    }

    private func observeStoreChanges() {
        withObservationTracking {
            _ = store.items
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                self?.updateStatusItemBadge()
                self?.observeStoreChanges()
            }
        }
    }

    private func updateStatusItemBadge() {
        let incompleteCount = store.items.filter { !$0.isCompleted }.count
        let text = " \(max(incompleteCount, 1))"
        let color: NSColor = incompleteCount > 0 ? .labelColor : .clear
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: color,
            .font: NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        ]
        statusItem.button?.attributedTitle = NSAttributedString(string: text, attributes: attrs)
    }

    @objc private func handleShowPopoverAndFocus() {
        showPopoverAndFocus()
    }

    @objc private func statusItemClicked() {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
    }

    private func showContextMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit JetGrind", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        // Clear the menu so left-click goes back to action-based handling
        statusItem.menu = nil
    }

    @objc private func openSettings() {
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
    }

    private func showPopoverAndFocus() {
        if !popover.isShown {
            showPopover()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: .focusTaskInput, object: nil)
        }
    }
}

extension Notification.Name {
    static let showPopoverAndFocus = Notification.Name("showPopoverAndFocus")
}
