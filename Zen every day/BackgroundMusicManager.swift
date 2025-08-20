import AVFoundation
import SwiftUI

class BackgroundMusicManager: ObservableObject {
    static let shared = BackgroundMusicManager()

    @Published private(set) var isPlaying: Bool = false
    private var audioPlayer: AVAudioPlayer?
    private let audioFiles: [String]
    private var currentAudio: String?
    private var userPaused: Bool = false

    @AppStorage("autoPlayMusic") private var autoPlayMusic: Bool = true
    @AppStorage("musicVolume") private var musicVolume: Double = 0.5

    private init() {
        var files: [String] = []
        var index = 1
        while index <= 1000 {
            let name = "audio\(index)"
            if NSDataAsset(name: name) != nil {
                files.append(name)
                index += 1
            } else {
                break
            }
        }
        self.audioFiles = files
    }

    func startIfNeeded() {
        guard autoPlayMusic, !userPaused else { return }
        if audioPlayer == nil {
            playRandomAudio()
        } else if !isPlaying {
            audioPlayer?.play()
            isPlaying = true
        }
    }

    func toggleAudio() {
        if let player = audioPlayer {
            if player.isPlaying {
                player.pause()
                isPlaying = false
                userPaused = true
            } else {
                player.play()
                isPlaying = true
                userPaused = false
            }
        } else {
            playRandomAudio()
            userPaused = false
        }
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func updateVolume() {
        audioPlayer?.volume = Float(musicVolume)
    }

    private func playRandomAudio() {
        guard let randomAudio = audioFiles.randomElement() else { return }
        currentAudio = randomAudio
        playSound(assetName: randomAudio)
    }

    private func playSound(assetName: String) {
        guard let audioAsset = NSDataAsset(name: assetName) else {
            debugLog("Could not load asset \(assetName)")
            return
        }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            audioPlayer = try AVAudioPlayer(data: audioAsset.data, fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer?.volume = Float(musicVolume)
            audioPlayer?.play()
            isPlaying = true
        } catch {
            debugLog("Error playing audio: \(error)")
            isPlaying = false
        }
    }
}
