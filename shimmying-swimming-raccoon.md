# Plan: Screenshot Mode Refactor

## Context
The app currently behaves as a menu bar app with two separate hotkeys (Cmd+Shift+3 for full screen, Cmd+Shift+4 for selection). The user wants:
1. **No menu bar presence** - dock app only
2. **Single hotkey** that enters a "screenshot mode" with a toolbar (like Windows 11 Snipping Tool) where the user picks Rectangle or Full Screen via mouse
3. **Configurable hotkey** - the settings UI currently only displays shortcuts, not edit them

## Changes Overview

### Delete
- `Features/MenuBar/MenuBarView.swift` - no longer needed

### Create (4 new files)
All under `Core/Capture/`:

1. **`ScreenshotModeCoordinator.swift`** - `@MainActor` singleton orchestrating the screenshot mode lifecycle:
   - `activate()` → checks permissions, pauses hotkey, creates dim overlays on all screens + toolbar panel
   - `selectRectangleMode()` → hides toolbar, enables mouse selection on overlays
   - `captureFullScreen()` → dismisses all windows, waits 150ms, captures via `AppState.shared.captureFullScreen()`
   - `dismiss()` → closes all windows, resumes hotkey
   - Selection complete callback → closes windows, waits 150ms, captures via `AppState.shared.captureSelection(rect:displayID:)`

2. **`ScreenshotToolbarPanel.swift`** - `NSPanel` subclass:
   - Borderless, floating, transparent background
   - Level: `NSWindow.Level(rawValue: NSWindow.Level.screenSaver.rawValue + 1)` (above overlays)
   - Hosts SwiftUI toolbar via `NSHostingView`
   - Centered horizontally, near top of the screen where the mouse cursor is
   - Escape key calls coordinator's `dismiss()`

3. **`ScreenshotToolbarView.swift`** - SwiftUI view inside the panel:
   - Dark rounded rectangle with: Rectangle button, Full Screen button, divider, X (close) button
   - Calls coordinator methods on button press

4. **`KeyRecorderView.swift`** (in `Features/Settings/`):
   - `NSViewRepresentable` wrapping a custom `NSView` that captures `keyDown` events
   - Pauses the global hotkey while recording to prevent conflicts
   - Validates at least one modifier key is present
   - Shows current shortcut when idle, "Press shortcut..." when recording
   - Escape cancels recording

### Modify

1. **`App/SuperOrganizedScreenshotsApp.swift`** - Remove the `MenuBarExtra` scene (lines 22-26)

2. **`Core/Hotkey/HotkeyManager.swift`** - Major rewrite:
   - Single `screenshotModeHotKey: HotKey?` instead of two
   - Single `@Published shortcut: KeyCombo` (default: Cmd+Shift+5)
   - Handler calls `ScreenshotModeCoordinator.shared.activate()`
   - `pauseHotkey()` / `resumeHotkey()` using HotKey library's `isPaused`
   - Persistence via `UserDefaults` using `carbonKeyCode` / `carbonFlags`
   - Remove all overlay management code (moves to coordinator)

3. **`App/AppDelegate.swift`** - Update method names: `registerHotkey()` / `unregisterHotkey()` (singular)

4. **`Features/Settings/SettingsView.swift`** - Replace `HotkeySettingsView`:
   - Single shortcut row with interactive `KeyRecorderView`
   - "Reset to Default" button
   - Updated help text

5. **`Core/Capture/SelectionOverlayWindow.swift`** - Add dual-mode support:
   - New `var isSelectionEnabled = false` property
   - Mouse handlers guarded by `isSelectionEnabled`
   - Crosshair cursor when selection enabled
   - Escape always calls coordinator's `dismiss()`
   - Keep `NSScreen.displayID` extension

### No changes needed
- `AppState.swift`, `ScreenCaptureManager.swift`, `ScreenshotStore.swift`, `UserPreferences.swift`, `Package.swift`, all Gallery/Editor files

## Verification
1. Build with `swift build`
2. Run the app - it should appear in the Dock only (no menu bar icon)
3. Press Cmd+Shift+5 - screen dims, toolbar appears at top center
4. Click Rectangle - toolbar hides, cursor becomes crosshair, draw a rectangle to capture
5. Press Cmd+Shift+5 again - click Full Screen - captures entire screen
6. Press Cmd+Shift+5 then Escape - dismisses without capture
7. Open Settings > Shortcuts - click the shortcut field, press a new key combo, verify it persists after app restart
