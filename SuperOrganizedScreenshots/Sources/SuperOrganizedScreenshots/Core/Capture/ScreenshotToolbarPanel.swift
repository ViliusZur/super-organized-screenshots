import AppKit
import SwiftUI

final class ScreenshotToolbarPanel: NSPanel {
    init(on screen: NSScreen) {
        let panelWidth: CGFloat = 260
        let panelHeight: CGFloat = 48

        let panelRect = NSRect(
            x: screen.frame.midX - panelWidth / 2,
            y: screen.frame.maxY - panelHeight - 80,
            width: panelWidth,
            height: panelHeight
        )

        super.init(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.isMovableByWindowBackground = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = false

        let hostingView = NSHostingView(rootView: ScreenshotToolbarView())
        self.contentView = hostingView
    }

    override var canBecomeKey: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            ScreenshotModeCoordinator.shared.dismiss()
        } else {
            super.keyDown(with: event)
        }
    }
}
