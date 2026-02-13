import SwiftUI
import ScreenCaptureKit

@MainActor
final class AppState: ObservableObject {
    static let shared = AppState()

    @Published var screenshots: [Screenshot] = []
    @Published var isCapturing: Bool = false
    @Published var selectedScreenshot: Screenshot?
    @Published var hasScreenRecordingPermission: Bool = false

    private let screenshotStore = ScreenshotStore()
    private let captureManager = ScreenCaptureManager()
    private let permissionManager = PermissionManager()

    private init() {
        Task {
            await checkPermissions()
            await loadScreenshots()
        }
    }

    func checkPermissions() async {
        hasScreenRecordingPermission = await permissionManager.checkScreenRecordingPermission()
    }

    func requestPermissions() {
        permissionManager.openScreenRecordingSettings()
    }

    func loadScreenshots() async {
        screenshots = await screenshotStore.loadAllScreenshots()
    }

    func captureFullScreen(displayID: CGDirectDisplayID? = nil) async throws -> Screenshot {
        isCapturing = true
        defer { isCapturing = false }

        let image = try await captureManager.captureFullScreen(displayID: displayID)
        let screenshot = try await screenshotStore.save(image: image)
        screenshots.insert(screenshot, at: 0)
        NSSound(named: "Grab")?.play()
        copyToClipboard(screenshot)
        sendScreenshotNotification(for: screenshot)
        return screenshot
    }

    func captureSelection(rect: CGRect, displayID: CGDirectDisplayID) async throws -> Screenshot {
        isCapturing = true
        defer { isCapturing = false }

        let image = try await captureManager.captureRegion(rect: rect, displayID: displayID)
        let screenshot = try await screenshotStore.save(image: image)
        screenshots.insert(screenshot, at: 0)
        NSSound(named: "Grab")?.play()
        copyToClipboard(screenshot)
        sendScreenshotNotification(for: screenshot)
        return screenshot
    }

    private func copyToClipboard(_ screenshot: Screenshot) {
        guard let image = NSImage(contentsOf: screenshot.url) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([image])
    }

    private func sendScreenshotNotification(for screenshot: Screenshot) {
        guard UserPreferences.shared.showNotification else { return }

        let panel = ScreenshotNotificationPanel(screenshot: screenshot)
        panel.show()
    }

    func deleteScreenshot(_ screenshot: Screenshot) async throws {
        try await screenshotStore.delete(screenshot)
        screenshots.removeAll { $0.id == screenshot.id }
    }

    func renameScreenshot(_ screenshot: Screenshot, to newName: String) async throws {
        let updated = try await screenshotStore.rename(screenshot, to: newName)
        if let index = screenshots.firstIndex(where: { $0.id == screenshot.id }) {
            screenshots[index] = updated
        }
    }

    func updateScreenshot(_ screenshot: Screenshot, with image: NSImage) async throws {
        try await screenshotStore.update(screenshot, with: image)
        if let index = screenshots.firstIndex(where: { $0.id == screenshot.id }) {
            screenshots[index].reloadThumbnail()
        }
    }
}
