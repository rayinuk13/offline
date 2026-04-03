import SwiftUI

struct PlaylistsView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var player: AudioPlayerService

    @State private var showCreateSheet = false
    @State private var newPlaylistName = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offlineBackground.ignoresSafeArea()

                if store.playlists.isEmpty {
                    EmptyPlaylistsView(showCreateSheet: $showCreateSheet)
                } else {
                    List {
                        ForEach(store.playlists) { playlist in
                            NavigationLink(destination: PlaylistDetailView(playlist: playlist)) {
                                PlaylistRowView(playlist: playlist)
                            }
                            .listRowBackground(Color.offlineSurface)
                            .listRowSeparatorTint(.white.opacity(0.08))
                        }
                        .onDelete { offsets in
                            store.deletePlaylists(at: offsets)
                        }
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .padding(.bottom, 140)
                }
            }
            .navigationTitle("Playlists")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.offlineAccent)
                    }
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreatePlaylistSheet(isPresented: $showCreateSheet)
            }
        }
    }
}

// MARK: - Playlist row

private struct PlaylistRowView: View {
    @EnvironmentObject var store: AppStore
    let playlist: Playlist

    private var items: [MediaItem] { playlist.resolvedItems(in: store.library) }

    var body: some View {
        HStack(spacing: 14) {
            PlaylistArtworkGrid(items: items)

            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text("\(playlist.itemCount) song\(playlist.itemCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Playlist artwork grid (2×2 mosaic)

struct PlaylistArtworkGrid: View {
    let items: [MediaItem]
    var size: CGFloat = 56

    var body: some View {
        let artworks = items.compactMap { $0.artworkData }.prefix(4)
        ZStack {
            if artworks.isEmpty {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(LinearGradient(
                        colors: [Color.offlineAccent.opacity(0.6), Color.purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                Image(systemName: "music.note.house.fill")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.white.opacity(0.85))
            } else if artworks.count < 4 {
                if let data = artworks.first, let img = UIImage(data: data) {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
                }
            } else {
                // 2×2 mosaic
                let half = size / 2
                LazyVGrid(columns: [GridItem(.fixed(half)), GridItem(.fixed(half))], spacing: 1) {
                    ForEach(0..<4, id: \.self) { i in
                        if let img = UIImage(data: artworks[i]) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: half, height: half)
                                .clipped()
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Empty state

private struct EmptyPlaylistsView: View {
    @Binding var showCreateSheet: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 64))
                .foregroundStyle(.offlineAccent.opacity(0.8))
            Text("No playlists yet")
                .font(.title2.weight(.semibold))
            Text("Create a playlist and add songs\nfrom your library.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                showCreateSheet = true
            } label: {
                Label("New Playlist", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(.offlineAccent)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
        }
        .padding()
    }
}

// MARK: - Create playlist sheet

struct CreatePlaylistSheet: View {
    @EnvironmentObject var store: AppStore
    @Binding var isPresented: Bool
    @State private var name = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offlineBackground.ignoresSafeArea()
                VStack(spacing: 24) {
                    TextField("Playlist Name", text: $name)
                        .font(.title3)
                        .padding()
                        .background(Color.offlineSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onSubmit { create() }
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("New Playlist")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { create() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .tint(.offlineAccent)
                }
            }
        }
        .presentationDetents([.height(200)])
        .onAppear { isFocused = true }
    }

    private func create() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        store.createPlaylist(name: trimmed)
        isPresented = false
    }
}
