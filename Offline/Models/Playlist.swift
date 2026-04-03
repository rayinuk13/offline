import Foundation

/// A user-created ordered collection of MediaItems.
struct Playlist: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var itemIDs: [UUID]
    var dateCreated: Date
    var dateModified: Date

    init(
        id: UUID = UUID(),
        name: String,
        itemIDs: [UUID] = [],
        dateCreated: Date = Date(),
        dateModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.itemIDs = itemIDs
        self.dateCreated = dateCreated
        self.dateModified = dateModified
    }

    var itemCount: Int { itemIDs.count }

    /// Returns an ordered list of MediaItems for this playlist, resolving IDs
    /// against the provided library.
    func resolvedItems(in library: [MediaItem]) -> [MediaItem] {
        itemIDs.compactMap { id in library.first { $0.id == id } }
    }

    /// Total playback duration across all resolved items.
    func totalDuration(in library: [MediaItem]) -> TimeInterval {
        resolvedItems(in: library).reduce(0) { $0 + $1.duration }
    }

    mutating func add(_ item: MediaItem) {
        guard !itemIDs.contains(item.id) else { return }
        itemIDs.append(item.id)
        dateModified = Date()
    }

    mutating func remove(at offsets: IndexSet) {
        itemIDs.remove(atOffsets: offsets)
        dateModified = Date()
    }

    mutating func move(from source: IndexSet, to destination: Int) {
        itemIDs.move(fromOffsets: source, toOffset: destination)
        dateModified = Date()
    }}

extension TimeInterval {
    /// Human-readable representation, e.g. "1 hr 23 min" or "45 min".
    var playlistDurationString: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}
