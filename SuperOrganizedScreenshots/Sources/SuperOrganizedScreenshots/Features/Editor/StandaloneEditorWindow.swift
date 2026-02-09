import AppKit
import SwiftUI

@MainActor
enum StandaloneEditorWindow {
    private static var editorWindow: NSWindow?

    static func open(for screenshot: Screenshot) {
        // Close any existing standalone editor
        editorWindow?.close()

        let editorView = ImageEditorView(screenshot: screenshot)
            .environmentObject(AppState.shared)
            .onDisappear {
                editorWindow?.close()
                editorWindow = nil
            }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 650),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = NSHostingView(rootView: editorView)
        window.title = "Edit - \(screenshot.displayName)"
        window.center()
        window.isReleasedWhenClosed = false

        editorWindow = window

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
