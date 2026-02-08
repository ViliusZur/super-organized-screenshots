import SwiftUI
import AppKit

struct CanvasView: NSViewRepresentable {
    @ObservedObject var viewModel: ImageEditorViewModel

    func makeNSView(context: Context) -> CanvasNSView {
        let view = CanvasNSView()
        view.delegate = context.coordinator
        view.image = viewModel.image
        return view
    }

    func updateNSView(_ nsView: CanvasNSView, context: Context) {
        nsView.image = viewModel.image
        nsView.annotations = viewModel.annotations
        nsView.currentTool = viewModel.selectedTool
        nsView.currentColor = NSColor(viewModel.selectedColor)
        nsView.strokeWidth = viewModel.strokeWidth
        nsView.fontSize = viewModel.fontSize
        nsView.needsDisplay = true
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, CanvasDelegate {
        let viewModel: ImageEditorViewModel

        init(viewModel: ImageEditorViewModel) {
            self.viewModel = viewModel
        }

        func canvasDidAddAnnotation(_ annotation: any Annotation) {
            Task { @MainActor in
                viewModel.addAnnotation(annotation)
            }
        }
    }
}

protocol CanvasDelegate: AnyObject {
    func canvasDidAddAnnotation(_ annotation: any Annotation)
}

final class CanvasNSView: NSView {
    weak var delegate: CanvasDelegate?

    var image: NSImage? {
        didSet { needsDisplay = true }
    }

    var annotations: [any Annotation] = [] {
        didSet { needsDisplay = true }
    }

    var currentTool: ToolType = .freehand
    var currentColor: NSColor = .red
    var strokeWidth: CGFloat = 3.0
    var fontSize: CGFloat = 24.0

    private var currentPoints: [CGPoint] = []
    private var arrowStartPoint: CGPoint?
    private var imageRect: CGRect = .zero

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        NSColor.windowBackgroundColor.setFill()
        bounds.fill()

        guard let image = image else { return }

        let imageAspect = image.size.width / image.size.height
        let boundsAspect = bounds.width / bounds.height

        if imageAspect > boundsAspect {
            let width = bounds.width * 0.9
            let height = width / imageAspect
            imageRect = CGRect(
                x: (bounds.width - width) / 2,
                y: (bounds.height - height) / 2,
                width: width,
                height: height
            )
        } else {
            let height = bounds.height * 0.9
            let width = height * imageAspect
            imageRect = CGRect(
                x: (bounds.width - width) / 2,
                y: (bounds.height - height) / 2,
                width: width,
                height: height
            )
        }

        image.draw(in: imageRect)

        let scale = imageRect.width / image.size.width

        context.saveGState()
        context.translateBy(x: imageRect.origin.x, y: imageRect.origin.y)

        for annotation in annotations {
            annotation.render(in: context, scale: scale)
        }

        drawCurrentStroke(in: context, scale: scale)

        context.restoreGState()
    }

    private func drawCurrentStroke(in context: CGContext, scale: CGFloat) {
        switch currentTool {
        case .freehand:
            if currentPoints.count > 1 {
                context.setStrokeColor(currentColor.cgColor)
                context.setLineWidth(strokeWidth * scale)
                context.setLineCap(.round)
                context.setLineJoin(.round)

                let scaledPoints = currentPoints.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }
                context.move(to: scaledPoints[0])
                for point in scaledPoints.dropFirst() {
                    context.addLine(to: point)
                }
                context.strokePath()
            }
        case .arrow:
            if let start = arrowStartPoint, currentPoints.count > 0, let end = currentPoints.last {
                context.setStrokeColor(currentColor.cgColor)
                context.setLineWidth(strokeWidth * scale)

                let scaledStart = CGPoint(x: start.x * scale, y: start.y * scale)
                let scaledEnd = CGPoint(x: end.x * scale, y: end.y * scale)

                context.move(to: scaledStart)
                context.addLine(to: scaledEnd)
                context.strokePath()
            }
        case .text:
            break
        }
    }

    private func convertToImageCoordinates(_ point: CGPoint) -> CGPoint? {
        guard imageRect.contains(point), let image = image else { return nil }

        let relativeX = (point.x - imageRect.origin.x) / imageRect.width
        let relativeY = (point.y - imageRect.origin.y) / imageRect.height

        return CGPoint(
            x: relativeX * image.size.width,
            y: relativeY * image.size.height
        )
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let imagePoint = convertToImageCoordinates(point) else { return }

        switch currentTool {
        case .freehand:
            currentPoints = [imagePoint]
        case .arrow:
            arrowStartPoint = imagePoint
            currentPoints = [imagePoint]
        case .text:
            showTextInput(at: imagePoint)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        guard let imagePoint = convertToImageCoordinates(point) else { return }

        switch currentTool {
        case .freehand:
            currentPoints.append(imagePoint)
        case .arrow:
            currentPoints = [imagePoint]
        case .text:
            break
        }

        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        switch currentTool {
        case .freehand:
            if currentPoints.count > 1 {
                let annotation = DrawingAnnotation(
                    points: currentPoints,
                    color: CodableColor(currentColor),
                    strokeWidth: strokeWidth
                )
                delegate?.canvasDidAddAnnotation(annotation)
            }
        case .arrow:
            if let start = arrowStartPoint, let end = currentPoints.last, start != end {
                let annotation = ArrowAnnotation(
                    startPoint: start,
                    endPoint: end,
                    color: CodableColor(currentColor),
                    strokeWidth: strokeWidth
                )
                delegate?.canvasDidAddAnnotation(annotation)
            }
        case .text:
            break
        }

        currentPoints = []
        arrowStartPoint = nil
        needsDisplay = true
    }

    private func showTextInput(at point: CGPoint) {
        let alert = NSAlert()
        alert.messageText = "Add Text"
        alert.informativeText = "Enter the text to add:"

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        textField.placeholderString = "Enter text..."
        alert.accessoryView = textField

        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            let text = textField.stringValue
            if !text.isEmpty {
                let annotation = TextAnnotation(
                    text: text,
                    position: point,
                    fontSize: fontSize,
                    color: CodableColor(currentColor)
                )
                delegate?.canvasDidAddAnnotation(annotation)
            }
        }
    }
}
