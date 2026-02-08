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

        let scale = CGFloat(fullImage.width) / CGFloat(NSScreen.main?.frame.width ?? CGFloat(fullImage.width))

        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: CGFloat(fullImage.height) - (rect.origin.y + rect.height) * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )

        guard let croppedImage = fullImage.cropping(to: scaledRect) else {
            throw CaptureError.croppingFailed
        }

        return croppedImage
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
