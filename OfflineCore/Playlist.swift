import Foundation

/// A user-created ordered collection of MediaItems.
public struct Playlist: Identifiable, Codable, Equatable, Sendable {
    public var id: UUID
    public var name: String
    public var itemIDs: [UUID]
    public var dateCreated: Date
    public var dateModified: Date

    public init(
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

    public var itemCount: Int { itemIDs.count }

    /// Returns an ordered list of MediaItems for this playlist, resolving IDs
    /// against the provided library.
    public func resolvedItems(in library: [MediaItem]) -> [MediaItem] {
        itemIDs.compactMap { id in library.first { $0.id == id } }
    }

    /// Total playback duration across all resolved items.
    public func totalDuration(in library: [MediaItem]) -> TimeInterval {
        resolvedItems(in: library).reduce(0) { $0 + $1.duration }
    }

    public mutating func add(_ item: MediaItem) {
        guard !itemIDs.contains(item.id) else { return }
        itemIDs.append(item.id)
        dateModified = Date()
    }

    public mutating func remove(at offsets: IndexSet) {
        let sorted = offsets.sorted().reversed()
        for index in sorted where index < itemIDs.count {
            itemIDs.remove(at: index)
        }
        dateModified = Date()
    }

    public mutating func move(from source: IndexSet, to destination: Int) {
        var result = itemIDs
        let movedItems = source.map { result[$0] }
        let sortedSource = source.sorted().reversed()
        for index in sortedSource { result.remove(at: index) }
        let insertAt = min(destination, result.count)
        result.insert(contentsOf: movedItems, at: insertAt)
        itemIDs = result
        dateModified = Date()
    }
}

extension TimeInterval {
    /// Human-readable representation, e.g. "1 hr 23 min" or "45 min".
    public var playlistDurationString: String {
        let hours = Int(self) / 3600
        let minutes = (Int(self) % 3600) / 60
        if hours > 0 {
            return "\(hours) hr \(minutes) min"
        }
        return "\(minutes) min"
    }
}
