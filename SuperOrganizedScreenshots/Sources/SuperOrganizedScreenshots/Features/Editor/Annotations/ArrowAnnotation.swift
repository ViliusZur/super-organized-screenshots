import Foundation
import CoreGraphics

struct ArrowAnnotation: Annotation {
    let id: UUID
    let startPoint: CGPoint
    let endPoint: CGPoint
    let color: CodableColor
    let strokeWidth: CGFloat

    init(id: UUID = UUID(), startPoint: CGPoint, endPoint: CGPoint, color: CodableColor, strokeWidth: CGFloat = 3) {
        self.id = id
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.color = color
        self.strokeWidth = strokeWidth
    }

    func render(in context: CGContext, scale: CGFloat) {
        let start = CGPoint(x: startPoint.x * scale, y: startPoint.y * scale)
        let end = CGPoint(x: endPoint.x * scale, y: endPoint.y * scale)

        context.setStrokeColor(color.cgColor)
        context.setFillColor(color.cgColor)
        context.setLineWidth(strokeWidth * scale)
        context.setLineCap(.round)

        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()

        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 15 * scale
        let arrowAngle: CGFloat = .pi / 6

        let point1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let point2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        context.move(to: end)
        context.addLine(to: point1)
        context.addLine(to: point2)
        context.closePath()
        context.fillPath()
    }
}
