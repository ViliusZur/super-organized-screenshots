import AppKit
import UniformTypeIdentifiers

actor ScreenshotStore {
    private let fileManager = FileManager.default
    private let baseURL: URL
    private let namingService = FileNamingService()

    init() {
        let picturesURL = fileManager.urls(for: .picturesDirectory, in: .userDomainMask).first!
        baseURL = picturesURL.appendingPathComponent("Super Organized Screenshots", isDirectory: true)

        if !fileManager.fileExists(atPath: baseURL.path) {
            try? fileManager.createDirectory(at: baseURL, withIntermediateDirectories: true)
        }
    }

    var storageURL: URL {
        baseURL
    }

    func save(image: CGImage) async throws -> Screenshot {
        let filename = namingService.generateFilename()
        let url = baseURL.appendingPathComponent(filename)

        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        guard let pngData = nsImage.pngData() else {
            throw StorageError.encodingFailed
        }

        try pngData.write(to: url)

        return Screenshot(
            id: UUID(),
            url: url,
            createdAt: Date(),
            filename: filename
        )
    }

    func loadAllScreenshots() async -> [Screenshot] {
        do {
            let urls = try fileManager.contentsOfDirectory(
                at: baseURL,
                includingPropertiesForKeys: [.creationDateKey, .contentModificationDateKey],
                options: [.skipsHiddenFiles]
            )

            let supportedExtensions = ["png", "jpg", "jpeg"]

            return urls
                .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
                .compactMap { url -> Screenshot? in
                    let attrs = try? fileManager.attributesOfItem(atPath: url.path)
                    let createdAt = attrs?[.creationDate] as? Date ?? Date()
                    return Screenshot(
                        id: UUID(),
                        url: url,
                        createdAt: createdAt,
                        filename: url.lastPathComponent
                    )
                }
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            return []
        }
    }

    func delete(_ screenshot: Screenshot) async throws {
        try fileManager.removeItem(at: screenshot.url)
    }

    func rename(_ screenshot: Screenshot, to newName: String) async throws -> Screenshot {
        let ext = screenshot.url.pathExtension
        var sanitizedName = newName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        if !sanitizedName.hasSuffix(".\(ext)") {
            sanitizedName += ".\(ext)"
        }

        let newURL = screenshot.url.deletingLastPathComponent().appendingPathComponent(sanitizedName)

        if fileManager.fileExists(atPath: newURL.path) {
            throw StorageError.fileAlreadyExists
        }

        try fileManager.moveItem(at: screenshot.url, to: newURL)

        return Screenshot(
            id: screenshot.id,
            url: newURL,
            createdAt: screenshot.createdAt,
            filename: sanitizedName
        )
    }

    func update(_ screenshot: Screenshot, with image: NSImage) async throws {
        guard let pngData = image.pngData() else {
            throw StorageError.encodingFailed
        }
        try pngData.write(to: screenshot.url)
    }
}

enum StorageError: LocalizedError {
    case encodingFailed
    case fileAlreadyExists
    case fileNotFound

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode image"
        case .fileAlreadyExists:
            return "A file with that name already exists"
        case .fileNotFound:
            return "File not found"
        }
    }
}
