import SwiftUI
import AppKit
import HotKey
import Carbon

struct KeyRecorderView: NSViewRepresentable {
    @Binding var keyCombo: KeyCombo
    var onRecordingStateChanged: ((Bool) -> Void)?

    func makeNSView(context: Context) -> KeyRecorderNSView {
        let view = KeyRecorderNSView()
        view.keyCombo = keyCombo
        view.onKeyComboChanged = { newCombo in
            keyCombo = newCombo
        }
        view.onRecordingStateChanged = onRecordingStateChanged
        return view
    }

    func updateNSView(_ nsView: KeyRecorderNSView, context: Context) {
        nsView.keyCombo = keyCombo
        if !nsView.isRecording {
            nsView.needsDisplay = true
        }
    }
}

final class KeyRecorderNSView: NSView {
    var keyCombo: KeyCombo = HotkeyManager.defaultShortcut
    var onKeyComboChanged: ((KeyCombo) -> Void)?
    var onRecordingStateChanged: ((Bool) -> Void)?
    var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 6
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 120, height: 28)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let bgColor: NSColor = isRecording ? .controlAccentColor.withAlphaComponent(0.15) : .controlBackgroundColor
        bgColor.setFill()
        let bgPath = NSBezierPath(roundedRect: bounds, xRadius: 6, yRadius: 6)
        bgPath.fill()

        let borderColor: NSColor = isRecording ? .controlAccentColor : .separatorColor
        borderColor.setStroke()
        let borderPath = NSBezierPath(roundedRect: bounds.insetBy(dx: 0.5, dy: 0.5), xRadius: 6, yRadius: 6)
        borderPath.lineWidth = 1
        borderPath.stroke()

        let text: String
        let textColor: NSColor
        if isRecording {
            text = "Press shortcut..."
            textColor = .secondaryLabelColor
        } else {
            text = keyCombo.displayString
            textColor = .labelColor
        }

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 13, weight: .medium),
            .foregroundColor: textColor
        ]
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attrString.size()
        let textPoint = NSPoint(
            x: (bounds.width - textSize.width) / 2,
            y: (bounds.height - textSize.height) / 2
        )
        attrString.draw(at: textPoint)
    }

    override func mouseDown(with event: NSEvent) {
        if !isRecording {
            startRecording()
        }
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        if event.keyCode == 53 { // Escape cancels recording
            stopRecording()
            return
        }

        let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard modifiers.contains(.command) || modifiers.contains(.control) || modifiers.contains(.option) else {
            // Require at least one modifier key
            NSSound.beep()
            return
        }

        guard let key = Key(carbonKeyCode: UInt32(event.keyCode)) else {
            NSSound.beep()
            return
        }

        let cleanModifiers = modifiers.intersection([.command, .shift, .option, .control])
        let newCombo = KeyCombo(key: key, modifiers: cleanModifiers)
        keyCombo = newCombo
        onKeyComboChanged?(newCombo)
        stopRecording()
    }

    override func flagsChanged(with event: NSEvent) {
        // Don't handle modifier-only presses as complete combos
    }

    private func startRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
        HotkeyManager.shared.pauseHotkey()
        onRecordingStateChanged?(true)
        needsDisplay = true
    }

    private func stopRecording() {
        isRecording = false
        HotkeyManager.shared.resumeHotkey()
        onRecordingStateChanged?(false)
        needsDisplay = true
    }
}
