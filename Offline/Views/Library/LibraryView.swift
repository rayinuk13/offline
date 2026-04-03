import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject var store: AppStore
    @EnvironmentObject var player: AudioPlayerService

    @State private var isImporting = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var searchText = ""
    @State private var selectedItem: MediaItem?
    @State private var showAddToPlaylist = false

    private var filteredItems: [MediaItem] {
        if searchText.isEmpty { return store.library }
        return store.library.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.artist.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.offlineBackground.ignoresSafeArea()

                if store.library.isEmpty {
                    EmptyLibraryView(isImporting: $isImporting)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredItems) { item in
                                MediaRowView(item: item)
                                    .onTapGesture {
                                        player.play(item: item, queue: filteredItems)
                                    }
                                    .contextMenu {
                                        Button {
                                            selectedItem = item
                                            showAddToPlaylist = true
                                        } label: {
                                            Label("Add to Playlist", systemImage: "music.note.house.fill")
                                        }
                                        Button(role: .destructive) {
                                            if let idx = store.library.firstIndex(where: { $0.id == item.id }) {
                                                store.removeItems(at: IndexSet(integer: idx))
                                            }
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                Divider()
                                    .background(Color.white.opacity(0.05))
                                    .padding(.leading, 76)
                            }
                        }
                        .padding(.bottom, 140) // space for mini-player + tab bar
                    }
                    .searchable(text: $searchText, prompt: "Search songs, artists…")
                }

                if isLoading {
                    ImportingOverlay()
                }
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isImporting = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.offlineAccent)
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: allowedTypes,
                allowsMultipleSelection: true
            ) { result in
                handleImport(result: result)
            }
            .alert("Import Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
            .sheet(isPresented: $showAddToPlaylist) {
                if let item = selectedItem {
                    AddToPlaylistSheet(item: item)
                }
            }
        }
    }

    private var allowedTypes: [UTType] {
        [UTType.mp3, UTType.mpeg4Audio, UTType.audio, UTType.movie, UTType.mpeg4Movie]
            .compactMap { $0 }
    }

    private func handleImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            isLoading = true
            Task {
                for url in urls {
                    do {
                        let item = try await FileImportService.importFile(from: url)
                        await MainActor.run { store.addItem(item) }
                    } catch {
                        await MainActor.run {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                }
                await MainActor.run { isLoading = false }
            }
        case .failure(let error):
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Empty state

private struct EmptyLibraryView: View {
    @Binding var isImporting: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note")
                .font(.system(size: 64))
                .foregroundStyle(.offlineAccent.opacity(0.8))
            Text("Your library is empty")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.primary)
            Text("Tap the button below to import\nMP3 or MP4 files from your device.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                isImporting = true
            } label: {
                Label("Upload Media", systemImage: "arrow.up.circle.fill")
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

// MARK: - Importing overlay

private struct ImportingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.offlineAccent)
                    .scaleEffect(1.5)
                Text("Importing…")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(32)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }
}
