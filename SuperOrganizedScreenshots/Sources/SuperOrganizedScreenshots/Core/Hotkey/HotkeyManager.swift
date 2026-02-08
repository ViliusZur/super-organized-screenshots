import AppKit
import HotKey
import Carbon

@MainActor
final class HotkeyManager: ObservableObject {
    static let shared = HotkeyManager()

    private var screenshotModeHotKey: HotKey?

    @Published var shortcut: KeyCombo {
        didSet {
            saveShortcut()
            registerHotkey()
        }
    }

    static let defaultShortcut = KeyCombo(key: .five, modifiers: [.command, .shift])

    private init() {
        self.shortcut = Self.defaultShortcut
        loadShortcut()
    }

    func registerHotkey() {
        unregisterHotkey()

        screenshotModeHotKey = HotKey(key: shortcut.key, modifiers: shortcut.modifiers)
        screenshotModeHotKey?.keyDownHandler = {
            Task { @MainActor in
                ScreenshotModeCoordinator.shared.activate()
            }
        }
    }

    func unregisterHotkey() {
        screenshotModeHotKey = nil
    }

    func pauseHotkey() {
        screenshotModeHotKey?.isPaused = true
    }

    func resumeHotkey() {
        screenshotModeHotKey?.isPaused = false
    }

    func updateShortcut(_ combo: KeyCombo) {
        shortcut = combo
    }

    func resetToDefault() {
        shortcut = Self.defaultShortcut
    }

    // MARK: - Persistence

    private func saveShortcut() {
        UserDefaults.standard.set(shortcut.carbonKeyCode, forKey: "hotkeyKeyCode")
        UserDefaults.standard.set(shortcut.carbonModifiers, forKey: "hotkeyModifiers")
    }

    private func loadShortcut() {
        let keyCode = UserDefaults.standard.integer(forKey: "hotkeyKeyCode")
        let modifiers = UserDefaults.standard.integer(forKey: "hotkeyModifiers")

        guard keyCode != 0 || modifiers != 0,
              let key = Key(carbonKeyCode: UInt32(keyCode)) else {
            return
        }

        let flags = carbonModifiersToNSEventFlags(UInt32(modifiers))
        shortcut = KeyCombo(key: key, modifiers: flags)
    }

    private func carbonModifiersToNSEventFlags(_ carbonModifiers: UInt32) -> NSEvent.ModifierFlags {
        var flags: NSEvent.ModifierFlags = []
        if carbonModifiers & UInt32(cmdKey) != 0 { flags.insert(.command) }
        if carbonModifiers & UInt32(shiftKey) != 0 { flags.insert(.shift) }
        if carbonModifiers & UInt32(optionKey) != 0 { flags.insert(.option) }
        if carbonModifiers & UInt32(controlKey) != 0 { flags.insert(.control) }
        return flags
    }
}

struct KeyCombo: Equatable {
    let key: Key
    let modifiers: NSEvent.ModifierFlags

    var displayString: String {
        var parts: [String] = []
        if modifiers.contains(.control) { parts.append("⌃") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.command) { parts.append("⌘") }
        parts.append(key.description)
        return parts.joined()
    }

    var carbonKeyCode: Int {
        Int(key.carbonKeyCode)
    }

    var carbonModifiers: Int {
        var carbon: UInt32 = 0
        if modifiers.contains(.command) { carbon |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { carbon |= UInt32(shiftKey) }
        if modifiers.contains(.option) { carbon |= UInt32(optionKey) }
        if modifiers.contains(.control) { carbon |= UInt32(controlKey) }
        return Int(carbon)
    }
}
