import Foundation
import Combine

/// Central observable store holding library items and playlists.
/// Persists data to JSON files in the app's Documents directory.
final class AppStore: ObservableObject {
    @Published var library: [MediaItem] = []
    @Published var playlists: [Playlist] = []

    private let libraryURL: URL
    private let playlistsURL: URL

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        libraryURL = docs.appendingPathComponent("library.json")
        playlistsURL = docs.appendingPathComponent("playlists.json")
        load()
    }

    // MARK: - Library

    func addItem(_ item: MediaItem) {
        library.append(item)
        save()
    }

    func removeItems(at offsets: IndexSet) {
        let items = offsets.map { library[$0] }
        // Remove physical files
        items.forEach { item in
            try? FileManager.default.removeItem(at: item.fileURL)
        }
        // Remove from all playlists
        let ids = Set(items.map { $0.id })
        for index in playlists.indices {
            playlists[index].itemIDs.removeAll { ids.contains($0) }
        }
        library.remove(atOffsets: offsets)
        save()
    }

    func updateItem(_ item: MediaItem) {
        guard let index = library.firstIndex(where: { $0.id == item.id }) else { return }
        library[index] = item
        save()
    }

    // MARK: - Playlists

    func createPlaylist(name: String) -> Playlist {
        let pl = Playlist(name: name)
        playlists.append(pl)
        save()
        return pl
    }

    func deletePlaylists(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        save()
    }

    func updatePlaylist(_ playlist: Playlist) {
        guard let index = playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        playlists[index] = playlist
        save()
    }

    func addItem(_ item: MediaItem, toPlaylist playlistID: UUID) {
        guard let index = playlists.firstIndex(where: { $0.id == playlistID }) else { return }
        playlists[index].add(item)
        save()
    }

    // MARK: - Persistence

    private func load() {
        if let data = try? Data(contentsOf: libraryURL),
           let decoded = try? JSONDecoder().decode([MediaItem].self, from: data) {
            library = decoded
        }
        if let data = try? Data(contentsOf: playlistsURL),
           let decoded = try? JSONDecoder().decode([Playlist].self, from: data) {
            playlists = decoded
        }
    }

    func save() {
        if let data = try? JSONEncoder().encode(library) {
            try? data.write(to: libraryURL, options: .atomic)
        }
        if let data = try? JSONEncoder().encode(playlists) {
            try? data.write(to: playlistsURL, options: .atomic)
        }
    }
}
