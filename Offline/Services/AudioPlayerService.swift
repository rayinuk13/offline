import AVFoundation
import Combine
import MediaPlayer
import UIKit

/// Manages audio/video playback with background-audio support and
/// lock-screen / Control Centre integration via MPNowPlayingInfoCenter.
final class AudioPlayerService: NSObject, ObservableObject {
    static let shared = AudioPlayerService()

    // MARK: - Published state
    @Published var currentItem: MediaItem?
    @Published var queue: [MediaItem] = []
    @Published var currentIndex: Int = 0
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var repeatMode: RepeatMode = .none
    @Published var isShuffled: Bool = false

    // MARK: - Private
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    private var originalQueue: [MediaItem] = []

    enum RepeatMode { case none, one, all }

    override private init() {
        super.init()
        setupAudioSession()
        setupRemoteCommands()
    }

    // MARK: - Audio session

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error)")
        }
    }

    // MARK: - Playback

    func play(item: MediaItem, queue: [MediaItem] = []) {
        originalQueue = queue.isEmpty ? [item] : queue
        self.queue = originalQueue
        currentIndex = self.queue.firstIndex(where: { $0.id == item.id }) ?? 0
        loadAndPlay(item: item)
    }

    func playPlaylist(_ items: [MediaItem], startingAt index: Int = 0) {
        guard !items.isEmpty else { return }
        originalQueue = items
        queue = items
        currentIndex = min(index, items.count - 1)
        loadAndPlay(item: queue[currentIndex])
    }

    private func loadAndPlay(item: MediaItem) {
        removeTimeObserver()
        let playerItem = AVPlayerItem(url: item.fileURL)

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        if player == nil {
            player = AVPlayer(playerItem: playerItem)
        } else {
            player?.replaceCurrentItem(with: playerItem)
        }

        addTimeObserver()
        currentItem = item
        duration = item.duration
        player?.play()
        isPlaying = true
        updateNowPlaying()
    }

    func togglePlayPause() {
        guard player != nil else { return }
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
        }
        isPlaying.toggle()
        updateNowPlayingRate()
    }

    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime) { [weak self] _ in
            self?.currentTime = time
            self?.updateNowPlaying()
        }
    }

    func skipForward(seconds: TimeInterval = 15) {
        seek(to: min(currentTime + seconds, duration))
    }

    func skipBackward(seconds: TimeInterval = 15) {
        seek(to: max(currentTime - seconds, 0))
    }

    func playNext() {
        switch repeatMode {
        case .one:
            seek(to: 0)
            player?.play()
            isPlaying = true
        case .none, .all:
            if currentIndex + 1 < queue.count {
                currentIndex += 1
            } else if repeatMode == .all {
                currentIndex = 0
            } else {
                isPlaying = false
                return
            }
            loadAndPlay(item: queue[currentIndex])
        }
    }

    func playPrevious() {
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        if currentIndex > 0 {
            currentIndex -= 1
        } else if repeatMode == .all {
            currentIndex = queue.count - 1
        }
        loadAndPlay(item: queue[currentIndex])
    }

    func toggleShuffle() {
        isShuffled.toggle()
        if isShuffled {
            var shuffled = queue
            if let current = currentItem,
               let idx = shuffled.firstIndex(where: { $0.id == current.id }) {
                shuffled.remove(at: idx)
                shuffled.shuffle()
                shuffled.insert(current, at: 0)
                queue = shuffled
                currentIndex = 0
            } else {
                shuffled.shuffle()
                queue = shuffled
            }
        } else {
            if let current = currentItem {
                queue = originalQueue
                currentIndex = queue.firstIndex(where: { $0.id == current.id }) ?? 0
            } else {
                queue = originalQueue
            }
        }
    }

    func toggleRepeat() {
        switch repeatMode {
        case .none: repeatMode = .all
        case .all:  repeatMode = .one
        case .one:  repeatMode = .none
        }
    }

    // MARK: - Time observation

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            self.currentTime = time.seconds
            if let item = self.player?.currentItem {
                let dur = item.duration.seconds
                if dur.isFinite && dur > 0 {
                    self.duration = dur
                }
            }
        }
    }

    private func removeTimeObserver() {
        if let obs = timeObserver {
            player?.removeTimeObserver(obs)
            timeObserver = nil
        }
    }

    @objc private func itemDidFinishPlaying() {
        DispatchQueue.main.async { [weak self] in
            self?.playNext()
        }
    }

    // MARK: - Now Playing / Remote Commands

    private func setupRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()

        center.playCommand.addTarget { [weak self] _ in
            self?.player?.play()
            self?.isPlaying = true
            self?.updateNowPlayingRate()
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            self?.player?.pause()
            self?.isPlaying = false
            self?.updateNowPlayingRate()
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        center.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        center.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self?.seek(to: e.positionTime)
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let item = currentItem else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: item.title,
            MPMediaItemPropertyArtist: item.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let data = item.artworkData, let image = UIImage(data: data) {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingRate() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
