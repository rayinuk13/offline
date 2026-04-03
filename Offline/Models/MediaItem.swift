import Foundation

/// Represents an audio or video media file imported by the user.
struct MediaItem: Identifiable, Codable, Equatable, Hashable {
    var id: UUID
    var title: String
    var artist: String
    var duration: TimeInterval
    /// Relative file name stored in the app's Documents directory.
    var fileName: String
    var mediaType: MediaType
    var dateAdded: Date
    var artworkData: Data?

    init(
        id: UUID = UUID(),
        title: String,
        artist: String = "Unknown Artist",
        duration: TimeInterval = 0,
        fileName: String,
        mediaType: MediaType,
        dateAdded: Date = Date(),
        artworkData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.fileName = fileName
        self.mediaType = mediaType
        self.dateAdded = dateAdded
        self.artworkData = artworkData
    }

    /// Full URL of the media file on disk.
    var fileURL: URL {
        FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(fileName)
    }

    /// Human-readable duration string (e.g. "3:45").
    var durationString: String {
        let total = Int(duration)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

enum MediaType: String, Codable, CaseIterable {
    case audio = "audio"
    case video = "video"

    var fileExtensions: [String] {
        switch self {
        case .audio: return ["mp3", "m4a", "aac", "wav", "flac"]
        case .video: return ["mp4", "mov", "m4v"]
        }
    }

    var systemImage: String {
        switch self {
        case .audio: return "music.note"
        case .video: return "play.rectangle.fill"
        }
    }
}
