import AppKit

@MainActor
final class ScreenshotModeCoordinator {
    static let shared = ScreenshotModeCoordinator()

    private var overlayWindows: [SelectionOverlayWindow] = []
    private var toolbarPanel: ScreenshotToolbarPanel?
    private var isActive = false

    private init() {}

    func activate() {
        guard !isActive else { return }

        guard AppState.shared.hasScreenRecordingPermission else {
            AppState.shared.requestPermissions()
            return
        }

        isActive = true
        HotkeyManager.shared.pauseHotkey()

        // Create dim overlays on all screens
        for screen in NSScreen.screens {
            let overlay = SelectionOverlayWindow(for: screen)
            overlay.isSelectionEnabled = false
            overlay.onCancel = { [weak self] in
                self?.dismiss()
            }
            overlayWindows.append(overlay)
            overlay.orderFrontRegardless()
        }

        // Create toolbar on the screen with the mouse cursor
        let mouseScreen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) })
            ?? NSScreen.main ?? NSScreen.screens[0]

        toolbarPanel = ScreenshotToolbarPanel(on: mouseScreen)
        toolbarPanel?.orderFrontRegardless()
        toolbarPanel?.makeKey()

        NSApp.activate(ignoringOtherApps: true)
    }

    func selectRectangleMode() {
        toolbarPanel?.orderOut(nil)

        for overlay in overlayWindows {
            overlay.isSelectionEnabled = true
            overlay.onSelectionComplete = { [weak self] rect, displayID in
                self?.handleSelectionComplete(rect: rect, displayID: displayID)
            }
        }

        // Make the overlay under the mouse key so it receives events
        if let mouseScreen = NSScreen.screens.first(where: { NSMouseInRect(NSEvent.mouseLocation, $0.frame, false) }),
           let overlay = overlayWindows.first(where: { $0.frame == mouseScreen.frame }) {
            overlay.makeKey()
        } else {
            overlayWindows.first?.makeKey()
        }
    }

    func captureFullScreen() {
        dismissAllWindows()
        NSApp.hide(nil)

        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)

            do {
                _ = try await AppState.shared.captureFullScreen()
            } catch {
                print("Full screen capture failed: \(error.localizedDescription)")
            }

            finalize()
        }
    }

    func dismiss() {
        dismissAllWindows()
        finalize()
    }

    private func handleSelectionComplete(rect: CGRect, displayID: CGDirectDisplayID) {
        dismissAllWindows()
        NSApp.hide(nil)

        Task {
            try? await Task.sleep(nanoseconds: 200_000_000)

            do {
                _ = try await AppState.shared.captureSelection(rect: rect, displayID: displayID)
            } catch {
                print("Selection capture failed: \(error.localizedDescription)")
            }

            finalize()
        }
    }

    private func dismissAllWindows() {
        toolbarPanel?.orderOut(nil)
        toolbarPanel = nil

        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }

    private func finalize() {
        isActive = false
        HotkeyManager.shared.resumeHotkey()
    }
}
