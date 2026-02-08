import SwiftUI
import AppKit

struct CodableColor: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double

    init(_ color: Color) {
        let nsColor = NSColor(color).usingColorSpace(.deviceRGB) ?? NSColor.red
        self.red = Double(nsColor.redComponent)
        self.green = Double(nsColor.greenComponent)
        self.blue = Double(nsColor.blueComponent)
        self.alpha = Double(nsColor.alphaComponent)
    }

    init(_ nsColor: NSColor) {
        let color = nsColor.usingColorSpace(.deviceRGB) ?? NSColor.red
        self.red = Double(color.redComponent)
        self.green = Double(color.greenComponent)
        self.blue = Double(color.blueComponent)
        self.alpha = Double(color.alphaComponent)
    }

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    var color: Color {
        Color(red: red, green: green, blue: blue, opacity: alpha)
    }

    var nsColor: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    var cgColor: CGColor {
        CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    static let red = CodableColor(red: 1, green: 0, blue: 0)
    static let green = CodableColor(red: 0, green: 1, blue: 0)
    static let blue = CodableColor(red: 0, green: 0, blue: 1)
    static let black = CodableColor(red: 0, green: 0, blue: 0)
    static let white = CodableColor(red: 1, green: 1, blue: 1)
    static let yellow = CodableColor(red: 1, green: 1, blue: 0)
    static let orange = CodableColor(red: 1, green: 0.5, blue: 0)
    static let purple = CodableColor(red: 0.5, green: 0, blue: 0.5)
}
