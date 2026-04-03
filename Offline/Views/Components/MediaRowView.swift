import SwiftUI

/// A single row representing a media item in a list.
struct MediaRowView: View {
    let item: MediaItem

    var body: some View {
        HStack(spacing: 12) {
            ArtworkThumbnail(artworkData: item.artworkData, mediaType: item.mediaType)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                    .foregroundStyle(.primary)
                Text(item.artist)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(item.durationString)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.offlineBackground)
        .contentShape(Rectangle())
    }
}

// MARK: - Artwork thumbnail

struct ArtworkThumbnail: View {
    let artworkData: Data?
    let mediaType: MediaType
    var size: CGFloat = 48

    var body: some View {
        Group {
            if let data = artworkData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: mediaType == .audio
                            ? [Color.offlineAccent.opacity(0.8), Color.offlineAccent.opacity(0.4)]
                            : [Color.indigo.opacity(0.8), Color.purple.opacity(0.4)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: mediaType.systemImage)
                        .font(.system(size: size * 0.4))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.2))
    }
}
