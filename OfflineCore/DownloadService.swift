import Foundation

/// Provides URLs for sharing/exporting playlist media files via the system share sheet.
public struct DownloadService {

    public enum DownloadError: LocalizedError {
        case noItems

        public var errorDescription: String? {
            switch self {
            case .noItems: return "The playlist contains no media files."
            }
        }
    }

    /// Returns the file URLs for all items in a playlist that exist on disk.
    /// These URLs can be passed to UIActivityViewController for sharing/saving.
    public static func fileURLs(for playlist: Playlist, items: [MediaItem]) throws -> [URL] {
        let urls = items.compactMap { item -> URL? in
            let url = item.fileURL
            return FileManager.default.fileExists(atPath: url.path) ? url : nil
        }
        guard !urls.isEmpty else { throw DownloadError.noItems }
        return urls
    }
}
