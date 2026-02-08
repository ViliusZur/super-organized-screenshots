# Super Organized Screenshots - macOS App Implementation Plan

## Overview
A native macOS screenshot application built with Swift and SwiftUI that captures, organizes, and edits screenshots with global hotkey support.

## Technology Stack
- **Language:** Swift 6
- **UI Framework:** SwiftUI (with AppKit for low-level operations)
- **Screen Capture:** ScreenCaptureKit (macOS 12.3+)
- **Global Hotkeys:** KeyboardShortcuts library (by Sindre Sorhus)
- **Minimum Target:** macOS 13.0 (for MenuBarExtra support)

## App Configuration
- **App Type:** Dock app (appears in Dock, with menu bar extra)
- **Distribution:** Mac App Store (sandboxed)
- **Sandbox Entitlements:** Pictures folder read/write access

## Project Structure

```
SuperOrganizedScreenshots/
├── SuperOrganizedScreenshots.xcodeproj
├── SuperOrganizedScreenshots/
│   ├── App/
│   │   ├── SuperOrganizedScreenshotsApp.swift    # Main app entry
│   │   ├── AppDelegate.swift                      # NSApplicationDelegate
│   │   └── AppState.swift                         # Global app state
│   │
│   ├── Core/
│   │   ├── Capture/
│   │   │   ├── ScreenCaptureManager.swift         # ScreenCaptureKit wrapper
│   │   │   ├── CaptureMode.swift                  # Enum: fullScreen, selection
│   │   │   ├── SelectionOverlayWindow.swift       # Selection rectangle window
│   │   │   └── SelectionView.swift                # SwiftUI selection visualization
│   │   │
│   │   ├── Hotkey/
│   │   │   ├── HotkeyManager.swift                # Global hotkey handling
│   │   │   └── HotkeyConfiguration.swift          # Hotkey preferences
│   │   │
│   │   ├── Storage/
│   │   │   ├── ScreenshotStore.swift              # File system operations
│   │   │   └── FileNamingService.swift            # Timestamp naming
│   │   │
│   │   └── Permissions/
│   │       └── PermissionManager.swift            # Screen recording permissions
│   │
│   ├── Features/
│   │   ├── Gallery/
│   │   │   ├── GalleryView.swift                  # Main gallery grid
│   │   │   ├── GalleryViewModel.swift             # Gallery logic
│   │   │   ├── ScreenshotThumbnailView.swift      # Thumbnail cell
│   │   │   └── ScreenshotDetailView.swift         # Full-size preview
│   │   │
│   │   ├── Editor/
│   │   │   ├── ImageEditorView.swift              # Main editing canvas
│   │   │   ├── ImageEditorViewModel.swift         # Editor state
│   │   │   ├── CanvasView.swift                   # Drawing canvas
│   │   │   ├── Tools/
│   │   │   │   ├── ToolType.swift                 # Tool enum
│   │   │   │   └── ToolPaletteView.swift          # Tool selector
│   │   │   ├── Annotations/
│   │   │   │   ├── Annotation.swift               # Protocol
│   │   │   │   ├── DrawingAnnotation.swift        # Freehand strokes
│   │   │   │   ├── TextAnnotation.swift           # Text overlays
│   │   │   │   └── ArrowAnnotation.swift          # Arrow shapes
│   │   │   ├── ColorPickerView.swift              # Color selection
│   │   │   └── AnnotationRenderer.swift           # Renders to image
│   │   │
│   │   ├── Settings/
│   │   │   ├── SettingsView.swift                 # Settings window
│   │   │   ├── HotkeySettingsView.swift           # Hotkey configuration
│   │   │   └── GeneralSettingsView.swift          # General prefs
│   │   │
│   │   └── MenuBar/
│   │       └── MenuBarView.swift                  # Menu bar popover
│   │
│   ├── Models/
│   │   ├── Screenshot.swift                       # Screenshot model
│   │   └── UserPreferences.swift                  # Preferences
│   │
│   ├── Extensions/
│   │   ├── CGImage+Extensions.swift
│   │   ├── NSImage+Extensions.swift
│   │   ├── Date+Extensions.swift
│   │   └── CodableColor.swift                     # Codable Color wrapper
│   │
│   └── Resources/
│       ├── Assets.xcassets
│       ├── Info.plist
│       └── SuperOrganizedScreenshots.entitlements
```

## Implementation Phases

### Phase 1: Project Setup & Core Infrastructure
1. Create Xcode project with SwiftUI App lifecycle
2. Add KeyboardShortcuts Swift Package dependency
3. Implement `PermissionManager` for screen recording permission
4. Implement `ScreenshotStore` for file operations
5. Implement `FileNamingService` with millisecond timestamp format
6. Create `Screenshot` model

### Phase 2: Screen Capture
7. Implement `ScreenCaptureManager` using ScreenCaptureKit
8. Implement full-screen capture mode
9. Create `SelectionOverlayWindow` for rectangle selection
10. Implement region capture with coordinate handling

### Phase 3: Global Hotkeys
11. Implement `HotkeyManager` with KeyboardShortcuts
12. Set default hotkeys (Cmd+Shift+3 full, Cmd+Shift+4 selection)
13. Wire hotkeys to capture actions

### Phase 4: Gallery & Management
14. Build `GalleryView` with LazyVGrid
15. Implement thumbnail loading
16. Create `ScreenshotDetailView` for preview
17. Add rename functionality
18. Add delete functionality with confirmation
19. Add context menus

### Phase 5: Image Editor
20. Create `ImageEditorView` layout
21. Implement `CanvasView` (NSViewRepresentable)
22. Add freehand drawing tool
23. Add text annotation tool
24. Add arrow tool
25. Implement `ColorPickerView`
26. Add undo/redo functionality
27. Implement save with rendered annotations

### Phase 6: Menu Bar & Settings
28. Implement MenuBarExtra with quick actions
29. Build `SettingsView` with hotkey configuration
30. Add general preferences (sound, notifications)

## Key Technical Details

### Screen Capture (ScreenCaptureKit)
```swift
let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
let display = content.displays.first!
let filter = SCContentFilter(display: display, excludingWindows: [])
let config = SCStreamConfiguration()
config.width = display.width
config.height = display.height
let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
```

### File Naming
Format: `Screenshot_YYYY-MM-DD_HH-mm-ss-SSS.png`
Example: `Screenshot_2025-02-08_14-32-45-123.png`

### Storage Location
`~/Pictures/Super Organized Screenshots/`

### Required Permissions
- **Screen Recording:** Required for ScreenCaptureKit (prompted automatically)
- **File Access:** Pictures folder access via entitlements

### Sandbox Entitlements (for Mac App Store)
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.assets.pictures.read-write</key>
<true/>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
```

### Dependencies
- KeyboardShortcuts (https://github.com/sindresorhus/KeyboardShortcuts)

## Verification
1. Build and run the Xcode project
2. Grant screen recording permission when prompted
3. Test Cmd+Shift+3 for full screen capture
4. Test Cmd+Shift+4 for selection capture
5. Verify screenshots appear in gallery ordered by recency
6. Test editing tools (draw, text, arrow)
7. Test rename and delete operations
8. Verify settings window allows hotkey customization
