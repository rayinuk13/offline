import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @StateObject private var player = AudioPlayerService.shared
    @State private var selectedTab: Tab = .library

    enum Tab { case library, playlists }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                LibraryView()
                    .tabItem {
                        Label("Library", systemImage: "music.note.list")
                    }
                    .tag(Tab.library)

                PlaylistsView()
                    .tabItem {
                        Label("Playlists", systemImage: "music.note.house.fill")
                    }
                    .tag(Tab.playlists)
            }
            .tint(.offlineAccent)

            // Mini-player pinned above the tab bar
            if player.currentItem != nil {
                MiniPlayerView()
                    .padding(.bottom, 49) // height of tab bar
            }
        }
        .environmentObject(player)
    }
}
