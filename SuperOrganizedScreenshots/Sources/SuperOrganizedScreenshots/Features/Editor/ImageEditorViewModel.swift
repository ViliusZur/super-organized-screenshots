import SwiftUI
import AppKit

@MainActor
final class ImageEditorViewModel: ObservableObject {
    @Published var image: NSImage
    @Published var annotations: [any Annotation] = []
    @Published var selectedTool: ToolType = .freehand
    @Published var selectedColor: Color = .red
    @Published var strokeWidth: CGFloat = 3.0
    @Published var fontSize: CGFloat = 24.0
    @Published var hasUnsavedChanges: Bool = false

    private var undoStack: [[any Annotation]] = []
    private var redoStack: [[any Annotation]] = []

    let screenshot: Screenshot

    init(screenshot: Screenshot) {
        self.screenshot = screenshot
        self.image = NSImage(contentsOf: screenshot.url) ?? NSImage()
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func addAnnotation(_ annotation: any Annotation) {
        undoStack.append(annotations)
        redoStack.removeAll()
        annotations.append(annotation)
        hasUnsavedChanges = true
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(annotations)
        annotations = previous
        hasUnsavedChanges = !undoStack.isEmpty
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(annotations)
        annotations = next
        hasUnsavedChanges = true
    }

    func renderFinalImage() -> NSImage {
        let size = image.size
        let finalImage = NSImage(size: size)

        finalImage.lockFocus()

        image.draw(in: NSRect(origin: .zero, size: size))

        if let context = NSGraphicsContext.current?.cgContext {
            for annotation in annotations {
                annotation.render(in: context, scale: 1.0)
            }
        }

        finalImage.unlockFocus()

        return finalImage
    }

    func save() async throws {
        let finalImage = renderFinalImage()
        guard let pngData = finalImage.pngData() else {
            throw EditorError.renderingFailed
        }
        try pngData.write(to: screenshot.url)
        image = finalImage
        annotations.removeAll()
        undoStack.removeAll()
        redoStack.removeAll()
        hasUnsavedChanges = false
    }
}

enum EditorError: LocalizedError {
    case renderingFailed

    var errorDescription: String? {
        switch self {
        case .renderingFailed:
            return "Failed to render the edited image"
        }
    }
}
