import SwiftUI
import AppKit

final class Screenshot: Identifiable, ObservableObject {
    let id: UUID
    var url: URL
    let createdAt: Date
    @Published var filename: String
    @Published private(set) var thumbnail: NSImage?

    init(id: UUID = UUID(), url: URL, createdAt: Date, filename: String) {
        self.id = id
        self.url = url
        self.createdAt = createdAt
        self.filename = filename
        loadThumbnail()
    }

    private func loadThumbnail() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if let image = NSImage(contentsOf: self.url) {
                let thumbnailSize = NSSize(width: 200, height: 150)
                let thumbnail = image.resized(to: thumbnailSize)
                DispatchQueue.main.async {
                    self.thumbnail = thumbnail
                }
            }
        }
    }

    func reloadThumbnail() {
        thumbnail = nil
        loadThumbnail()
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: createdAt)
    }

    var displayName: String {
        let name = (filename as NSString).deletingPathExtension
        return name
    }
}

extension Screenshot: Equatable {
    static func == (lhs: Screenshot, rhs: Screenshot) -> Bool {
        lhs.id == rhs.id
    }
}

extension Screenshot: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
