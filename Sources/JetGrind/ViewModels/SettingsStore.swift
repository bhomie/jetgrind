import AppKit
import HotKey

@MainActor
@Observable
final class SettingsStore {
    private static let keyCodeKey = "jetgrind.hotkey.keyCode"
    private static let modifiersKey = "jetgrind.hotkey.modifiers"

    private static let defaultKeyCode: UInt32 = Key.t.carbonKeyCode
    private static let defaultModifiers: UInt32 = NSEvent.ModifierFlags([.command, .shift]).carbonFlags

    var carbonKeyCode: UInt32
    var carbonModifiers: UInt32
    var hotKey: HotKey?

    var displayString: String {
        KeyCombo(carbonKeyCode: carbonKeyCode, carbonModifiers: carbonModifiers).description
    }

    init() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: Self.keyCodeKey) != nil {
            carbonKeyCode = UInt32(defaults.integer(forKey: Self.keyCodeKey))
            carbonModifiers = UInt32(defaults.integer(forKey: Self.modifiersKey))
        } else {
            carbonKeyCode = Self.defaultKeyCode
            carbonModifiers = Self.defaultModifiers
        }
        registerHotKey()
    }

    func registerHotKey() {
        hotKey = nil
        let hk = HotKey(carbonKeyCode: carbonKeyCode, carbonModifiers: carbonModifiers)
        hk.keyDownHandler = {
            Task { @MainActor in
                NotificationCenter.default.post(name: .showPopoverAndFocus, object: nil)
            }
        }
        hotKey = hk
    }

    func updateHotKey(keyCode: UInt32, modifiers: UInt32) {
        carbonKeyCode = keyCode
        carbonModifiers = modifiers
        UserDefaults.standard.set(Int(keyCode), forKey: Self.keyCodeKey)
        UserDefaults.standard.set(Int(modifiers), forKey: Self.modifiersKey)
        registerHotKey()
    }
}
