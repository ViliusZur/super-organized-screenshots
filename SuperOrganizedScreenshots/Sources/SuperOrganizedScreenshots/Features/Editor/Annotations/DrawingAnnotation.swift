import Foundation
import CoreGraphics

struct DrawingAnnotation: Annotation {
    let id: UUID
    let points: [CGPoint]
    let color: CodableColor
    let strokeWidth: CGFloat

    init(id: UUID = UUID(), points: [CGPoint], color: CodableColor, strokeWidth: CGFloat) {
        self.id = id
        self.points = points
        self.color = color
        self.strokeWidth = strokeWidth
    }

    func render(in context: CGContext, scale: CGFloat) {
        guard points.count > 1 else { return }

        context.setStrokeColor(color.cgColor)
        context.setLineWidth(strokeWidth * scale)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        let scaledPoints = points.map { CGPoint(x: $0.x * scale, y: $0.y * scale) }

        context.move(to: scaledPoints[0])
        for point in scaledPoints.dropFirst() {
            context.addLine(to: point)
        }
        context.strokePath()
    }
}
