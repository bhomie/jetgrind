import SwiftUI
import AppKit
import HotKey

struct HotKeyRecorderView: View {
    @Bindable var settingsStore: SettingsStore
    @State private var isRecording = false

    var body: some View {
        HStack {
            if isRecording {
                Text("Press shortcut...")
                    .foregroundStyle(.secondary)
                    .frame(minWidth: 80)
                KeyCaptureRepresentable(
                    settingsStore: settingsStore,
                    isRecording: $isRecording
                )
                .frame(width: 0, height: 0)
            } else {
                Text(settingsStore.displayString)
                    .font(.system(.body, design: .rounded))
                    .frame(minWidth: 80)
            }
            Button(isRecording ? "Cancel" : "Record") {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            }
        }
    }

    private func startRecording() {
        settingsStore.hotKey?.isPaused = true
        isRecording = true
    }

    private func stopRecording() {
        isRecording = false
        settingsStore.hotKey?.isPaused = false
    }
}

// MARK: - NSViewRepresentable wrapper

private struct KeyCaptureRepresentable: NSViewRepresentable {
    let settingsStore: SettingsStore
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> KeyCaptureView {
        let view = KeyCaptureView()
        view.onCapture = { keyCode, modifiers in
            Task { @MainActor in
                settingsStore.updateHotKey(keyCode: keyCode, modifiers: modifiers)
                isRecording = false
            }
        }
        view.onCancel = {
            Task { @MainActor in
                isRecording = false
                settingsStore.hotKey?.isPaused = false
            }
        }
        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }
        return view
    }

    func updateNSView(_ nsView: KeyCaptureView, context: Context) {}
}

// MARK: - Key capture NSView

private final class KeyCaptureView: NSView {
    var onCapture: ((UInt32, UInt32) -> Void)?
    var onCancel: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        let keyCode = UInt32(event.keyCode)
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // Escape cancels
        if event.keyCode == 53 {
            onCancel?()
            return
        }

        // Require at least one modifier
        let requiredModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        guard !flags.intersection(requiredModifiers).isEmpty else { return }

        // Reject modifier-only keys
        let modifierKeyCodes: Set<UInt16> = [55, 56, 58, 59, 54, 60, 61, 62, 63, 57] // cmd, shift, opt, ctrl variants, fn, capslock
        guard !modifierKeyCodes.contains(event.keyCode) else { return }

        let carbonMods = flags.carbonFlags
        onCapture?(keyCode, carbonMods)
    }

    override func flagsChanged(with event: NSEvent) {
        // Ignore modifier-only events
    }
}
