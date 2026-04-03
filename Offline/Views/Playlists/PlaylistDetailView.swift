import SwiftUI

struct PlaylistDetailView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var player: AudioPlayerService

    var playlist: Playlist {
        store.playlists.first(where: { $0.id == _playlist.id }) ?? _playlist
    }
    private let _playlist: Playlist

    @State private var showAddSongs = false
    @State private var showShareSheet = false
    @State private var shareURLs: [URL] = []
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isRenaming = false
    @State private var newName = ""

    init(playlist: Playlist) {
        _playlist = playlist
    }

    private var items: [MediaItem] { playlist.resolvedItems(in: store.library) }

    var body: some View {
        ZStack {
            Color.offlineBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    PlaylistHeaderView(
                        playlist: playlist,
                        items: items,
                        onPlay: { player.playPlaylist(items) },
                        onShuffle: {
                            player.playPlaylist(items)
                            if !player.isShuffled { player.toggleShuffle() }
                        },
                        onDownload: exportPlaylist
                    )

                    // Track list
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            MediaRowView(item: item)
                                .onTapGesture {
                                    player.playPlaylist(items, startingAt: index)
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        removeItem(item)
                                    } label: {
                                        Label("Remove from Playlist", systemImage: "minus.circle")
                                    }
                                }
                            Divider()
                                .background(Color.white.opacity(0.05))
                                .padding(.leading, 76)
                        }
                    }

                    // Add songs button
                    Button {
                        showAddSongs = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Songs")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.offlineAccent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                    }

                    Spacer().frame(height: 140)
                }
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        newName = playlist.name
                        isRenaming = true
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button {
                        exportPlaylist()
                    } label: {
                        Label("Download / Share", systemImage: "arrow.down.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(.offlineAccent)
                }
            }
        }
        .sheet(isPresented: $showAddSongs) {
            AddSongsToPlaylistView(playlist: playlist)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareURLs)
        }
        .alert("Export Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .alert("Rename Playlist", isPresented: $isRenaming) {
            TextField("Name", text: $newName)
            Button("Save") { renamePlaylist() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func removeItem(_ item: MediaItem) {
        guard let idx = store.playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        if let itemIdx = store.playlists[idx].itemIDs.firstIndex(of: item.id) {
            store.playlists[idx].remove(at: IndexSet(integer: itemIdx))
            store.save()
        }
    }

    private func exportPlaylist() {
        do {
            let urls = try DownloadService.fileURLs(for: playlist, items: items)
            shareURLs = urls
            showShareSheet = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func renamePlaylist() {
        let trimmed = newName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let idx = store.playlists.firstIndex(where: { $0.id == playlist.id }) else { return }
        store.playlists[idx].name = trimmed
        store.save()
    }
}

// MARK: - Playlist header

private struct PlaylistHeaderView: View {
    let playlist: Playlist
    let items: [MediaItem]
    let onPlay: () -> Void
    let onShuffle: () -> Void
    let onDownload: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            PlaylistArtworkGrid(items: items, size: 160)
                .shadow(color: .black.opacity(0.4), radius: 20, y: 8)

            VStack(spacing: 6) {
                Text(playlist.name)
                    .font(.title2.weight(.bold))
                Text("\(items.count) songs • \(playlist.totalDuration(in: items).playlistDurationString)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                PlaybackButton(
                    title: "Play",
                    icon: "play.fill",
                    style: .filled,
                    action: onPlay
                )
                PlaybackButton(
                    title: "Shuffle",
                    icon: "shuffle",
                    style: .outlined,
                    action: onShuffle
                )
                Button {
                    onDownload()
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.offlineAccent)
                }
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
    }
}

private struct PlaybackButton: View {
    enum Style { case filled, outlined }

    let title: String
    let icon: String
    let style: Style
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(style == .filled ? Color.offlineAccent : Color.offlineAccent.opacity(0.15))
            .foregroundStyle(style == .filled ? .white : .offlineAccent)
            .clipShape(Capsule())
        }
    }
}

// MARK: - Add songs sheet

private struct AddSongsToPlaylistView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.dismiss) private var dismiss
    let playlist: Playlist

    var availableItems: [MediaItem] {
        store.library.filter { !playlist.itemIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offlineBackground.ignoresSafeArea()
                if availableItems.isEmpty {
                    Text("All songs already added")
                        .foregroundStyle(.secondary)
                } else {
                    List(availableItems) { item in
                        Button {
                            store.addItem(item, toPlaylist: playlist.id)
                        } label: {
                            MediaRowView(item: item)
                        }
                        .listRowBackground(Color.offlineSurface)
                        .listRowSeparatorTint(.white.opacity(0.08))
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Add Songs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .tint(.offlineAccent)
                }
            }
        }
    }
}

// MARK: - Share sheet wrapper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
