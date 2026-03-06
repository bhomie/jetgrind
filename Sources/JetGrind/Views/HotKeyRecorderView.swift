import SwiftUI
import AppKit

struct HotKeyRecorderView: View {
    @Bindable var settingsStore: SettingsStore
    @State private var isRecording = false
    @State private var monitor = KeyEventMonitor()

    var body: some View {
        LabeledContent {
            Button(isRecording ? "Cancel" : "Record") {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
        } label: {
            Text(isRecording ? "Press shortcut..." : settingsStore.displayString)
                .font(.system(size: Theme.Font.body, design: .rounded))
                .foregroundStyle(isRecording ? .secondary : .primary)
                .frame(maxHeight: .infinity, alignment: .center)
        }
    }

    private func startRecording() {
        settingsStore.hotKey?.isPaused = true
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        isRecording = true
        monitor.start(
            onCapture: { keyCode, modifiers in
                settingsStore.updateHotKey(keyCode: keyCode, modifiers: modifiers)
                stopRecording()
            },
            onCancel: { stopRecording() }
        )
    }

    private func stopRecording() {
        monitor.stop()
        isRecording = false
        settingsStore.hotKey?.isPaused = false
        NSApp.setActivationPolicy(.accessory)
    }
}

// MARK: - Local key event monitor

@MainActor
private final class KeyEventMonitor {
    private var monitor: Any?

    func start(onCapture: @escaping (UInt32, UInt32) -> Void, onCancel: @escaping () -> Void) {
        stop()
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Escape cancels
            if event.keyCode == 53 {
                onCancel()
                return nil
            }

            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

            // Require at least one modifier
            let requiredModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
            guard !flags.intersection(requiredModifiers).isEmpty else { return nil }

            // Reject modifier-only keys
            let modifierKeyCodes: Set<UInt16> = [55, 56, 58, 59, 54, 60, 61, 62, 63, 57]
            guard !modifierKeyCodes.contains(event.keyCode) else { return nil }

            let keyCode = UInt32(event.keyCode)
            let carbonMods = flags.carbonFlags
            onCapture(keyCode, carbonMods)
            return nil
        }
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
