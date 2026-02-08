import Foundation

struct FileNamingService {
    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd_HH-mm-ss-SSS"
        return f
    }()

    func generateFilename(extension ext: String = "png") -> String {
        let timestamp = formatter.string(from: Date())
        return "Screenshot_\(timestamp).\(ext)"
    }

    func parseDate(from filename: String) -> Date? {
        let name = (filename as NSString).deletingPathExtension
        guard name.hasPrefix("Screenshot_") else { return nil }
        let dateString = String(name.dropFirst("Screenshot_".count))
        return formatter.date(from: dateString)
    }
}
