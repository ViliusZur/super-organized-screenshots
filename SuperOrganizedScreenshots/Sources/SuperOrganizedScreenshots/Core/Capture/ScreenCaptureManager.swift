import ScreenCaptureKit
import AppKit

@MainActor
final class ScreenCaptureManager {
    private var availableContent: SCShareableContent?

    func refreshContent() async throws {
        availableContent = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
    }

    func captureFullScreen(displayID: CGDirectDisplayID? = nil) async throws -> CGImage {
        try await refreshContent()

        guard let displays = availableContent?.displays, !displays.isEmpty else {
            throw CaptureError.noDisplayAvailable
        }

        let display: SCDisplay
        if let targetID = displayID {
            guard let found = displays.first(where: { $0.displayID == targetID }) else {
                throw CaptureError.displayNotFound
            }
            display = found
        } else {
            display = displays[0]
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = display.width
        config.height = display.height
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false

        return try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: config
        )
    }

    func captureRegion(rect: CGRect, displayID: CGDirectDisplayID? = nil) async throws -> CGImage {
        let fullImage = try await captureFullScreen(displayID: displayID)

        // Rect is in global (Cocoa) coordinates; get this display's frame in the same coordinate system.
        let displayFrame = displayFrameInGlobalCoordinates(for: displayID)
        let scale = CGFloat(fullImage.width) / displayFrame.width

        // Convert to display-local coordinates (same origin as captured image: bottom-left of this display).
        let localRect = CGRect(
            x: rect.origin.x - displayFrame.origin.x,
            y: rect.origin.y - displayFrame.origin.y,
            width: rect.width,
            height: rect.height
        )

        // Convert to image coordinates (top-left origin) and scale to pixel dimensions.
        let scaledRect = CGRect(
            x: localRect.origin.x * scale,
            y: CGFloat(fullImage.height) - (localRect.origin.y + localRect.height) * scale,
            width: localRect.width * scale,
            height: localRect.height * scale
        )

        guard let croppedImage = fullImage.cropping(to: scaledRect) else {
            throw CaptureError.croppingFailed
        }

        return croppedImage
    }

    /// Returns the display's frame in global Cocoa coordinates (origin bottom-left) for the given display ID.
    private func displayFrameInGlobalCoordinates(for displayID: CGDirectDisplayID?) -> CGRect {
        if let id = displayID,
           let screen = NSScreen.screens.first(where: { $0.displayID == id }) {
            return screen.frame
        }
        return NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1920, height: 1080)
    }

    func getAvailableDisplays() async throws -> [SCDisplay] {
        try await refreshContent()
        return availableContent?.displays ?? []
    }
}

enum CaptureError: LocalizedError {
    case noDisplayAvailable
    case displayNotFound
    case croppingFailed
    case captureFailed

    var errorDescription: String? {
        switch self {
        case .noDisplayAvailable:
            return "No display available for capture"
        case .displayNotFound:
            return "Specified display not found"
        case .croppingFailed:
            return "Failed to crop the captured image"
        case .captureFailed:
            return "Screen capture failed"
        }
    }
}
