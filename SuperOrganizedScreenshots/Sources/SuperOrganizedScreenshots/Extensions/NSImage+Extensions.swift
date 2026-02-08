import AppKit

extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage {
        let ratioX = targetSize.width / size.width
        let ratioY = targetSize.height / size.height
        let ratio = min(ratioX, ratioY)

        let newSize = NSSize(
            width: size.width * ratio,
            height: size.height * ratio
        )

        let newImage = NSImage(size: newSize)
        newImage.lockFocus()
        draw(
            in: NSRect(origin: .zero, size: newSize),
            from: NSRect(origin: .zero, size: size),
            operation: .copy,
            fraction: 1.0
        )
        newImage.unlockFocus()
        return newImage
    }

    func pngData() -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapRep.representation(using: .png, properties: [:])
    }

    func jpegData(quality: CGFloat = 0.9) -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }
}
