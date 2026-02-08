import Foundation
import CoreGraphics

protocol Annotation: Identifiable {
    var id: UUID { get }
    func render(in context: CGContext, scale: CGFloat)
}
