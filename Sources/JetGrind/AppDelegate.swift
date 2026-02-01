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
    private var hotKey: HotKey!
    private let store = TodoStore()

    func applicationDidFinishLaunching(_ notification: Notification) {
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
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: TodoListView(store: store))
    }

    private func setupHotKey() {
        hotKey = HotKey(key: .t, modifiers: [.command, .shift])
        hotKey.keyDownHandler = {
            Task { @MainActor in
                NotificationCenter.default.post(name: .showPopoverAndFocus, object: nil)
            }
        }

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
        statusItem.button?.title = incompleteCount > 0 ? " \(incompleteCount)" : ""
    }

    @objc private func handleShowPopoverAndFocus() {
        showPopoverAndFocus()
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            showPopover()
        }
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
