import XCTest
@testable import OfflineCore

final class OfflineTests: XCTestCase {

    // MARK: - MediaItem tests

    func testMediaItemDurationString() {
        let item = MediaItem(title: "Test", fileName: "test.mp3", mediaType: .audio, duration: 225)
        XCTAssertEqual(item.durationString, "3:45")
    }

    func testMediaItemDurationStringZero() {
        let item = MediaItem(title: "Test", fileName: "test.mp3", mediaType: .audio, duration: 0)
        XCTAssertEqual(item.durationString, "0:00")
    }

    func testMediaItemFileURL() {
        let item = MediaItem(title: "Test", fileName: "test.mp3", mediaType: .audio)
        XCTAssertTrue(item.fileURL.lastPathComponent == "test.mp3")
    }

    // MARK: - Playlist tests

    func testPlaylistAdd() {
        var playlist = Playlist(name: "My Playlist")
        let item = MediaItem(title: "Song 1", fileName: "song1.mp3", mediaType: .audio)
        playlist.add(item)
        XCTAssertEqual(playlist.itemCount, 1)
        XCTAssertTrue(playlist.itemIDs.contains(item.id))
    }

    func testPlaylistAddDuplicate() {
        var playlist = Playlist(name: "My Playlist")
        let item = MediaItem(title: "Song 1", fileName: "song1.mp3", mediaType: .audio)
        playlist.add(item)
        playlist.add(item) // duplicate
        XCTAssertEqual(playlist.itemCount, 1)
    }

    func testPlaylistRemove() {
        var playlist = Playlist(name: "My Playlist")
        let item = MediaItem(title: "Song 1", fileName: "song1.mp3", mediaType: .audio)
        playlist.add(item)
        playlist.remove(at: IndexSet(integer: 0))
        XCTAssertEqual(playlist.itemCount, 0)
    }

    func testPlaylistResolvedItems() {
        var playlist = Playlist(name: "Mix")
        let item1 = MediaItem(title: "A", fileName: "a.mp3", mediaType: .audio)
        let item2 = MediaItem(title: "B", fileName: "b.mp3", mediaType: .audio)
        let library = [item1, item2]
        playlist.add(item1)
        playlist.add(item2)
        let resolved = playlist.resolvedItems(in: library)
        XCTAssertEqual(resolved.count, 2)
        XCTAssertEqual(resolved[0].id, item1.id)
    }

    func testPlaylistTotalDuration() {
        var playlist = Playlist(name: "Mix")
        let item1 = MediaItem(title: "A", fileName: "a.mp3", mediaType: .audio, duration: 180)
        let item2 = MediaItem(title: "B", fileName: "b.mp3", mediaType: .audio, duration: 240)
        let library = [item1, item2]
        playlist.add(item1)
        playlist.add(item2)
        XCTAssertEqual(playlist.totalDuration(in: library), 420)
    }

    func testPlaylistMove() {
        var playlist = Playlist(name: "Mix")
        let item1 = MediaItem(title: "A", fileName: "a.mp3", mediaType: .audio)
        let item2 = MediaItem(title: "B", fileName: "b.mp3", mediaType: .audio)
        playlist.add(item1)
        playlist.add(item2)
        playlist.move(from: IndexSet(integer: 1), to: 0)
        XCTAssertEqual(playlist.itemIDs[0], item2.id)
    }

    // MARK: - MediaType tests

    func testMediaTypeAudioExtensions() {
        XCTAssertTrue(MediaType.audio.fileExtensions.contains("mp3"))
        XCTAssertTrue(MediaType.audio.fileExtensions.contains("m4a"))
    }

    func testMediaTypeVideoExtensions() {
        XCTAssertTrue(MediaType.video.fileExtensions.contains("mp4"))
        XCTAssertTrue(MediaType.video.fileExtensions.contains("mov"))
    }

    // MARK: - TimeInterval extension tests

    func testPlaylistDurationStringMinutes() {
        let duration: TimeInterval = 2700 // 45 min
        XCTAssertEqual(duration.playlistDurationString, "45 min")
    }

    func testPlaylistDurationStringHours() {
        let duration: TimeInterval = 5400 // 1 hr 30 min
        XCTAssertEqual(duration.playlistDurationString, "1 hr 30 min")
    }

    // MARK: - DownloadService tests

    func testDownloadServiceEmptyItems() {
        let playlist = Playlist(name: "Empty")
        XCTAssertThrowsError(try DownloadService.fileURLs(for: playlist, items: []))
    }

    func testDownloadServiceReturnsURLs() throws {
        // Write a real file directly into the "Documents" location the item will look for
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try FileManager.default.createDirectory(at: docs, withIntermediateDirectories: true)
        let fileName = "test_\(UUID()).mp3"
        let destURL = docs.appendingPathComponent(fileName)
        try Data("fake mp3".utf8).write(to: destURL)
        defer { try? FileManager.default.removeItem(at: destURL) }

        var playlist = Playlist(name: "Test")
        let item = MediaItem(title: "Test", fileName: fileName, mediaType: .audio)
        playlist.add(item)

        let urls = try DownloadService.fileURLs(for: playlist, items: [item])
        XCTAssertEqual(urls.count, 1)
        XCTAssertEqual(urls[0].lastPathComponent, fileName)
    }
}

// Convenience MediaItem init with duration for test readability
private extension MediaItem {
    init(title: String, fileName: String, mediaType: MediaType, duration: TimeInterval = 0) {
        self.init(
            title: title,
            duration: duration,
            fileName: fileName,
            mediaType: mediaType
        )
    }
}
