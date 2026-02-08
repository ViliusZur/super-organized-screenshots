import AppKit
import SwiftUI

final class SelectionOverlayWindow: NSWindow {
    var onSelectionComplete: ((CGRect, CGDirectDisplayID) -> Void)?
    var onCancel: (() -> Void)?

    var isSelectionEnabled = false {
        didSet {
            if isSelectionEnabled {
                NSCursor.crosshair.push()
            } else {
                NSCursor.pop()
            }
        }
    }

    private var startPoint: CGPoint = .zero
    private var currentRect: CGRect = .zero
    private var selectionView: SelectionOverlayView?
    private let displayID: CGDirectDisplayID

    init(for screen: NSScreen) {
        self.displayID = screen.displayID

        super.init(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.isOpaque = false
        self.hasShadow = false
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.acceptsMouseMovedEvents = true

        let view = SelectionOverlayView(frame: screen.frame)
        self.selectionView = view
        self.contentView = view
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard isSelectionEnabled else { return }
        startPoint = event.locationInWindow
        currentRect = CGRect(origin: startPoint, size: .zero)
        selectionView?.selectionRect = currentRect
    }

    override func mouseDragged(with event: NSEvent) {
        guard isSelectionEnabled else { return }
        let currentPoint = event.locationInWindow
        currentRect = CGRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
        selectionView?.selectionRect = currentRect
        selectionView?.needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isSelectionEnabled else { return }
        guard currentRect.width > 5 && currentRect.height > 5 else {
            return
        }

        let screenFrame = frame
        let adjustedRect = CGRect(
            x: currentRect.origin.x + screenFrame.origin.x,
            y: currentRect.origin.y + screenFrame.origin.y,
            width: currentRect.width,
            height: currentRect.height
        )

        onSelectionComplete?(adjustedRect, displayID)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape key
            ScreenshotModeCoordinator.shared.dismiss()
        }
    }
}

final class SelectionOverlayView: NSView {
    var selectionRect: CGRect = .zero

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.black.withAlphaComponent(0.3).setFill()
        bounds.fill()

        if selectionRect.width > 0 && selectionRect.height > 0 {
            guard let context = NSGraphicsContext.current?.cgContext else { return }
            context.setBlendMode(.clear)
            context.fill(selectionRect)
            context.setBlendMode(.normal)

            let path = NSBezierPath(rect: selectionRect)
            NSColor.white.setStroke()
            path.lineWidth = 1
            path.stroke()

            let dashedPath = NSBezierPath(rect: selectionRect)
            dashedPath.setLineDash([4, 4], count: 2, phase: 0)
            NSColor.systemBlue.setStroke()
            dashedPath.lineWidth = 1
            dashedPath.stroke()

            drawDimensions()
        }
    }

    private func drawDimensions() {
        let width = Int(selectionRect.width)
        let height = Int(selectionRect.height)
        let text = "\(width) × \(height)"

        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]

        let attributedString = NSAttributedString(string: " \(text) ", attributes: attributes)
        let textSize = attributedString.size()

        var textPoint = CGPoint(
            x: selectionRect.midX - textSize.width / 2,
            y: selectionRect.maxY + 5
        )

        if textPoint.y + textSize.height > bounds.maxY - 10 {
            textPoint.y = selectionRect.minY - textSize.height - 5
        }

        attributedString.draw(at: textPoint)
    }
}

extension NSScreen {
    var displayID: CGDirectDisplayID {
        let key = NSDeviceDescriptionKey("NSScreenNumber")
        return deviceDescription[key] as? CGDirectDisplayID ?? 0
    }
}
