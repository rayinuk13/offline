import SwiftUI

/// Full-screen now-playing view.
struct PlayerView: View {
    @EnvironmentObject var player: AudioPlayerService
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            // Blurred background
            if let data = player.currentItem?.artworkData, let img = UIImage(data: data) {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()
                    .blur(radius: 60)
                    .overlay(Color.black.opacity(0.65))
            } else {
                LinearGradient(
                    colors: [Color.offlineAccent.opacity(0.6), Color.offlineBackground],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }

            VStack(spacing: 0) {
                // Drag handle
                Capsule()
                    .fill(.white.opacity(0.25))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 20)

                // Artwork
                ArtworkThumbnail(
                    artworkData: player.currentItem?.artworkData,
                    mediaType: player.currentItem?.mediaType ?? .audio,
                    size: 280
                )
                .shadow(color: .black.opacity(0.5), radius: 30, y: 15)
                .padding(.bottom, 36)

                // Title & artist
                VStack(spacing: 6) {
                    Text(player.currentItem?.title ?? "Nothing Playing")
                        .font(.title2.weight(.bold))
                        .lineLimit(1)
                    Text(player.currentItem?.artist ?? "—")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.7))
                        .lineLimit(1)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 28)

                // Progress bar
                ProgressSlider()
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                // Playback controls
                PlaybackControls()
                    .padding(.horizontal, 32)
                    .padding(.bottom, 24)

                // Secondary controls (shuffle / repeat / queue)
                SecondaryControls()
                    .padding(.horizontal, 40)

                Spacer()
            }
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Progress slider

private struct ProgressSlider: View {
    @EnvironmentObject var player: AudioPlayerService
    @State private var isDragging = false
    @State private var dragValue: Double = 0

    var body: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { isDragging ? dragValue : player.currentTime },
                    set: { dragValue = $0 }
                ),
                in: 0...max(player.duration, 1),
                onEditingChanged: { editing in
                    isDragging = editing
                    if !editing { player.seek(to: dragValue) }
                }
            )
            .tint(.white)

            HStack {
                Text(timeString(player.currentTime))
                Spacer()
                Text(timeString(player.duration))
            }
            .font(.caption2.monospacedDigit())
            .foregroundStyle(.white.opacity(0.6))
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        let total = Int(max(t, 0))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}

// MARK: - Playback controls

private struct PlaybackControls: View {
    @EnvironmentObject var player: AudioPlayerService

    var body: some View {
        HStack(spacing: 0) {
            // Previous
            Button { player.playPrevious() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 28))
            }
            .frame(maxWidth: .infinity)

            // Play / Pause (large)
            Button { player.togglePlayPause() } label: {
                ZStack {
                    Circle()
                        .fill(.white)
                        .frame(width: 72, height: 72)
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.offlineBackground)
                        .offset(x: player.isPlaying ? 0 : 2)
                }
            }
            .frame(maxWidth: .infinity)

            // Next
            Button { player.playNext() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 28))
            }
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
    }
}

// MARK: - Secondary controls

private struct SecondaryControls: View {
    @EnvironmentObject var player: AudioPlayerService

    var body: some View {
        HStack {
            // Skip back 15s
            Button { player.skipBackward() } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 22))
            }
            Spacer()

            // Shuffle
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 20))
                    .foregroundStyle(player.isShuffled ? Color.offlineAccent : .white.opacity(0.6))
            }

            Spacer()

            // Repeat
            Button { player.toggleRepeat() } label: {
                repeatIcon
                    .font(.system(size: 20))
            }

            Spacer()

            // Skip forward 15s
            Button { player.skipForward() } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 22))
            }
        }
        .foregroundStyle(.white.opacity(0.8))
    }

    @ViewBuilder
    private var repeatIcon: some View {
        switch player.repeatMode {
        case .none:
            Image(systemName: "repeat").foregroundStyle(.white.opacity(0.4))
        case .all:
            Image(systemName: "repeat").foregroundStyle(Color.offlineAccent)
        case .one:
            Image(systemName: "repeat.1").foregroundStyle(Color.offlineAccent)
        }
    }
}
