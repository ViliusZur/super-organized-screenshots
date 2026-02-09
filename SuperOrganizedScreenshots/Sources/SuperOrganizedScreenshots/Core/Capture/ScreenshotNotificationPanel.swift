import AppKit
import SwiftUI

final class ScreenshotNotificationPanel: NSPanel {
    private var autoDismissTimer: Timer?
    private let screenshotID: String

    init(screenshot: Screenshot) {
        self.screenshotID = screenshot.id.uuidString

        let panelWidth: CGFloat = 320
        let panelHeight: CGFloat = 80

        let screen = NSScreen.main ?? NSScreen.screens[0]
        let panelRect = NSRect(
            x: screen.visibleFrame.maxX - panelWidth - 16,
            y: screen.visibleFrame.maxY - panelHeight - 16,
            width: panelWidth,
            height: panelHeight
        )

        super.init(
            contentRect: panelRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .floating
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hidesOnDeactivate = false
        self.isMovableByWindowBackground = false

        let notificationView = ScreenshotNotificationView(
            screenshot: screenshot,
            onTap: { [weak self] in
                self?.handleTap()
            },
            onDismiss: { [weak self] in
                self?.dismissNotification()
            }
        )
        self.contentView = NSHostingView(rootView: notificationView)
    }

    func show() {
        orderFrontRegardless()
        animateIn()

        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.dismissNotification()
            }
        }
    }

    private func handleTap() {
        autoDismissTimer?.invalidate()
        animateOut { [weak self] in
            guard let self else { return }
            self.orderOut(nil)
            if let uuid = UUID(uuidString: self.screenshotID),
               let screenshot = AppState.shared.screenshots.first(where: { $0.id == uuid }) {
                StandaloneEditorWindow.open(for: screenshot)
            }
        }
    }

    private func dismissNotification() {
        autoDismissTimer?.invalidate()
        animateOut { [weak self] in
            self?.orderOut(nil)
        }
    }

    private func animateIn() {
        alphaValue = 0
        let originalFrame = frame
        setFrame(frame.offsetBy(dx: 20, dy: 0), display: false)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            self.animator().alphaValue = 1
            self.animator().setFrame(originalFrame, display: true)
        }
    }

    private func animateOut(completion: @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
            self.animator().setFrame(frame.offsetBy(dx: 20, dy: 0), display: true)
        }, completionHandler: completion)
    }
}

struct ScreenshotNotificationView: View {
    let screenshot: Screenshot
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 3) {
                Text("Screenshot Captured")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)

                Text(screenshot.displayName)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                Text("Click to edit")
                    .font(.system(size: 10))
                    .foregroundColor(.tertiaryLabelColor)
            }

            Spacer()

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .padding(4)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    @ViewBuilder
    private var thumbnailView: some View {
        if let image = NSImage(contentsOf: screenshot.url) {
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
        }
    }
}

private extension Color {
    static var tertiaryLabelColor: Color {
        Color(nsColor: .tertiaryLabelColor)
    }
}
