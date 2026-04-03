import SwiftUI

/// Compact player bar shown above the tab bar when something is playing.
struct MiniPlayerView: View {
    @EnvironmentObject var player: AudioPlayerService
    @State private var showFullPlayer = false

    var body: some View {
        Button {
            showFullPlayer = true
        } label: {
            HStack(spacing: 12) {
                ArtworkThumbnail(
                    artworkData: player.currentItem?.artworkData,
                    mediaType: player.currentItem?.mediaType ?? .audio,
                    size: 44
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(player.currentItem?.title ?? "")
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    Text(player.currentItem?.artist ?? "")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 20) {
                    Button {
                        player.playPrevious()
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 18))
                    }

                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 22))
                    }

                    Button {
                        player.playNext()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 18))
                    }
                }
                .foregroundStyle(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                // Progress bar at the bottom
                GeometryReader { geo in
                    let progress = player.duration > 0 ? player.currentTime / player.duration : 0
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.offlineAccent)
                        .frame(width: geo.size.width * progress, height: 2)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                , alignment: .bottom
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.3), radius: 12, y: 4)
            .padding(.horizontal, 10)
        }
        .buttonStyle(.plain)
        .fullScreenCover(isPresented: $showFullPlayer) {
            PlayerView()
                .environmentObject(player)
        }
    }
}
