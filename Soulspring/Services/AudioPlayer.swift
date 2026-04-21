import Foundation
import AVFoundation
import MediaPlayer
import Combine

/// Soulspring's audio player. Wraps AVPlayer with:
/// - Background playback (configured via AVAudioSession .playback)
/// - Lock-screen controls (Now Playing center + remote command center)
/// - AirPods / external headphone routing handled by the system
///
/// Acts as an `ObservableObject` so views observe the current track,
/// playback state and progress without polling.
@MainActor
final class SoulAudioPlayer: ObservableObject {
    static let shared = SoulAudioPlayer()

    @Published private(set) var current: AudioTrack?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var elapsed: Double = 0
    @Published private(set) var duration: Double = 0

    private let player = AVPlayer()
    private var timeObserver: Any?
    private var endObserver: Any?

    private init() {
        configureSession()
        configureRemoteCommands()
        startTimeObserver()
    }

    // MARK: Public API

    func play(_ track: AudioTrack) {
        if current?.id == track.id {
            resume()
            return
        }

        current = track
        duration = Double(track.durationSec)

        let item: AVPlayerItem
        if let res = track.bundleResource,
           let url = Bundle.main.url(forResource: res, withExtension: "m4a")
                ?? Bundle.main.url(forResource: res, withExtension: "mp3") {
            item = AVPlayerItem(url: url)
        } else if let url = track.url {
            item = AVPlayerItem(url: url)
        } else {
            // Placeholder track without audio source — start "playing" but
            // there's no actual audio. Lets the UI demo work without files.
            isPlaying = true
            updateNowPlaying()
            return
        }

        player.replaceCurrentItem(with: item)
        attachEndObserver(to: item)
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func togglePlayPause() {
        isPlaying ? pause() : resume()
    }

    func pause() {
        player.pause()
        isPlaying = false
        updateNowPlaying()
    }

    func resume() {
        guard current != nil else { return }
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func stop() {
        player.pause()
        player.replaceCurrentItem(with: nil)
        current = nil
        isPlaying = false
        elapsed = 0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    func skip(by seconds: Double) {
        let target = max(0, min(duration, elapsed + seconds))
        seek(to: target)
    }

    func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: 1)
        player.seek(to: time)
        elapsed = seconds
        updateNowPlaying()
    }

    // MARK: Setup

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.mixWithOthers, .allowBluetoothA2DP, .allowAirPlay]
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    private func configureRemoteCommands() {
        let cc = MPRemoteCommandCenter.shared()

        cc.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.resume() }
            return .success
        }
        cc.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.pause() }
            return .success
        }
        cc.togglePlayPauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
        cc.skipForwardCommand.preferredIntervals = [15]
        cc.skipForwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skip(by: 15) }
            return .success
        }
        cc.skipBackwardCommand.preferredIntervals = [15]
        cc.skipBackwardCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.skip(by: -15) }
            return .success
        }
        cc.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self,
                  let e = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            Task { @MainActor in self.seek(to: e.positionTime) }
            return .success
        }
    }

    private func startTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 2)
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                guard let self else { return }
                self.elapsed = time.seconds.isFinite ? time.seconds : 0
                self.updateNowPlaying()
            }
        }
    }

    private func attachEndObserver(to item: AVPlayerItem) {
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime, object: item, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.isPlaying = false
                self.elapsed = self.duration
                self.updateNowPlaying()
            }
        }
    }

    private func updateNowPlaying() {
        guard let track = current else { return }
        var info: [String: Any] = [:]
        info[MPMediaItemPropertyTitle]            = track.title
        info[MPMediaItemPropertyArtist]           = track.teacher
        info[MPMediaItemPropertyAlbumTitle]       = "Soulspring · \(track.category.rawValue)"
        info[MPMediaItemPropertyPlaybackDuration] = duration
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsed
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}
