import SwiftUI

/// A sheet for choosing which playlist to add a given item to.
struct AddToPlaylistSheet: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let item: MediaItem

    @State private var showCreate = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offlineBackground.ignoresSafeArea()

                if store.playlists.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.house.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.offlineAccent.opacity(0.7))
                        Text("No playlists yet")
                            .font(.title3.weight(.medium))
                        Button("Create Playlist") {
                            showCreate = true
                        }
                        .tint(.offlineAccent)
                    }
                } else {
                    List(store.playlists) { playlist in
                        Button {
                            store.addItem(item, toPlaylist: playlist.id)
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                let items = playlist.resolvedItems(in: store.library)
                                PlaylistArtworkGrid(items: items, size: 44)
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(playlist.name)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    let alreadyAdded = playlist.itemIDs.contains(item.id)
                                    Text(alreadyAdded ? "Already added" : "\(playlist.itemCount) songs")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                if playlist.itemIDs.contains(item.id) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.offlineAccent)
                                }
                            }
                        }
                        .listRowBackground(Color.offlineSurface)
                        .listRowSeparatorTint(.white.opacity(0.08))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add to Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        showCreate = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .tint(.offlineAccent)
                }
            }
            .sheet(isPresented: $showCreate) {
                CreatePlaylistSheet(isPresented: $showCreate)
            }
        }
    }
}
