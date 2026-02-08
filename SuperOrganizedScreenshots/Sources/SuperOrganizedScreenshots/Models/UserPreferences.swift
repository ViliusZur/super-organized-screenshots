import SwiftUI

final class UserPreferences: ObservableObject {
    static let shared = UserPreferences()

    @AppStorage("playCaptureSound") var playCaptureSound: Bool = true
    @AppStorage("showNotificationAfterCapture") var showNotification: Bool = true
    @AppStorage("imageFormat") var imageFormat: ImageFormat = .png

    private init() {}
}

enum ImageFormat: String, CaseIterable, Identifiable {
    case png = "png"
    case jpeg = "jpeg"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .png: return "PNG"
        case .jpeg: return "JPEG"
        }
    }
}
