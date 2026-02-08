import Foundation
import CoreGraphics
import CoreText
import AppKit

struct TextAnnotation: Annotation {
    let id: UUID
    let text: String
    let position: CGPoint
    let fontSize: CGFloat
    let color: CodableColor

    init(id: UUID = UUID(), text: String, position: CGPoint, fontSize: CGFloat = 24, color: CodableColor) {
        self.id = id
        self.text = text
        self.position = position
        self.fontSize = fontSize
        self.color = color
    }

    func render(in context: CGContext, scale: CGFloat) {
        let scaledFontSize = fontSize * scale
        let scaledPosition = CGPoint(x: position.x * scale, y: position.y * scale)

        let font = CTFontCreateWithName("Helvetica-Bold" as CFString, scaledFontSize, nil)

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color.cgColor
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let line = CTLineCreateWithAttributedString(attributedString)

        context.saveGState()
        context.textMatrix = CGAffineTransform.identity
        context.translateBy(x: scaledPosition.x, y: scaledPosition.y)

        CTLineDraw(line, context)
        context.restoreGState()
    }
}
