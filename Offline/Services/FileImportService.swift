import Foundation
import AVFoundation
import UIKit

/// Handles importing media files from the system document picker,
/// copying them into the app's Documents directory, and reading metadata.
struct FileImportService {

    static let supportedExtensions = ["mp3", "mp4", "m4a", "aac", "wav", "mov", "m4v"]
    static let supportedUTIs = [
        "public.mp3",
        "public.mpeg-4-audio",
        "com.apple.m4a-audio",
        "public.aac-audio",
        "com.microsoft.waveform-audio",
        "public.mpeg-4",
        "public.movie"
    ]

    /// Imports a file from a URL (which may be a security-scoped resource)
    /// into the app's Documents directory and returns a MediaItem.
    static func importFile(from url: URL) async throws -> MediaItem {
        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let ext = url.pathExtension.lowercased()
        let fileName = "\(UUID().uuidString).\(ext)"
        let destination = docs.appendingPathComponent(fileName)

        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: url, to: destination)

        // Extract metadata
        let asset = AVURLAsset(url: destination)
        let title = await extractTitle(from: asset, fallback: url.deletingPathExtension().lastPathComponent)
        let artist = await extractArtist(from: asset)
        let duration = try await asset.load(.duration).seconds
        let artworkData = await extractArtwork(from: asset)
        let mediaType: MediaType = ["mp4", "mov", "m4v"].contains(ext) ? .video : .audio

        return MediaItem(
            title: title,
            artist: artist,
            duration: duration.isFinite ? duration : 0,
            fileName: fileName,
            mediaType: mediaType,
            artworkData: artworkData
        )
    }

    // MARK: - Metadata helpers

    private static func extractTitle(from asset: AVURLAsset, fallback: String) async -> String {
        let items = try? await asset.loadMetadata(for: .id3Metadata)
        if let item = items?.first(where: { $0.commonKey == .commonKeyTitle }),
           let value = try? await item.load(.stringValue) {
            return value
        }
        let common = try? await asset.loadMetadata(for: .iTunesMetadata)
        if let item = common?.first(where: { $0.commonKey == .commonKeyTitle }),
           let value = try? await item.load(.stringValue) {
            return value
        }
        return fallback
    }

    private static func extractArtist(from asset: AVURLAsset) async -> String {
        let items = try? await asset.loadMetadata(for: .id3Metadata)
        if let item = items?.first(where: { $0.commonKey == .commonKeyArtist }),
           let value = try? await item.load(.stringValue) {
            return value
        }
        let common = try? await asset.loadMetadata(for: .iTunesMetadata)
        if let item = common?.first(where: { $0.commonKey == .commonKeyArtist }),
           let value = try? await item.load(.stringValue) {
            return value
        }
        return "Unknown Artist"
    }

    private static func extractArtwork(from asset: AVURLAsset) async -> Data? {
        let items = try? await asset.loadMetadata(for: .id3Metadata)
        if let item = items?.first(where: { $0.commonKey == .commonKeyArtwork }),
           let data = try? await item.load(.dataValue) {
            return data
        }
        let common = try? await asset.loadMetadata(for: .iTunesMetadata)
        if let item = common?.first(where: { $0.commonKey == .commonKeyArtwork }),
           let data = try? await item.load(.dataValue) {
            return data
        }
        return nil
    }
}
