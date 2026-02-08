import SwiftUI

enum ToolType: String, CaseIterable, Identifiable {
    case freehand
    case arrow
    case text

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .freehand: return "Draw"
        case .arrow: return "Arrow"
        case .text: return "Text"
        }
    }

    var iconName: String {
        switch self {
        case .freehand: return "pencil.tip"
        case .arrow: return "arrow.up.right"
        case .text: return "textformat"
        }
    }
}
