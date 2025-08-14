import Foundation
import AVFoundation

@MainActor
class VerseSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    static let shared = VerseSpeaker()
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking: Bool = false
    var isPaused: Bool = false
    private var ignoreFinishCallbacks = false

    private var verses: [Verse] = []
    private var currentIndex: Int = 0
    private var onVerseCompletion: ((Verse) -> Void)?

    var currentVerseIndex: Int { currentIndex }

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    private func configureUtterance(_ utterance: AVSpeechUtterance) {
        if let siri = AVSpeechSynthesisVoice.speechVoices().first(where: { voice in
            voice.language == "en-US" && voice.name.contains("Siri")
        }) {
            utterance.voice = siri
        } else if let enhanced = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.language == "en-US" && $0.quality == .enhanced }) {
            utterance.voice = enhanced
        } else if let alex = AVSpeechSynthesisVoice(identifier: AVSpeechSynthesisVoiceIdentifierAlex) {
            utterance.voice = alex
        }
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.75
        utterance.pitchMultiplier = 1.0
    }

    func speak(text: String) {
        guard !text.isEmpty else { return }
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        let utterance = AVSpeechUtterance(string: text)
        configureUtterance(utterance)
        synthesizer.speak(utterance)
        isPaused = false
        isSpeaking = true
    }

    func speak(verses: [Verse], startAt index: Int = 0, onVerseCompletion: @escaping (Verse) -> Void) {
        stop()
        self.verses = verses
        self.currentIndex = index
        self.onVerseCompletion = onVerseCompletion
        isPaused = false
        speakCurrentVerse()
    }

    func pause() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.pauseSpeaking(at: .word)
        isSpeaking = false
        isPaused = true
    }

    func resume() {
        guard isPaused else { return }
        synthesizer.continueSpeaking()
        isSpeaking = true
        isPaused = false
    }

    private func speakCurrentVerse() {
        guard currentIndex < verses.count else {
            isSpeaking = false
            return
        }

        let verse = verses[currentIndex]
        let utterance = AVSpeechUtterance(string: verse.text.cleanVerse)
        configureUtterance(utterance)
        synthesizer.speak(utterance)
        isPaused = false
        isSpeaking = true
    }

    func stop() {
        if synthesizer.isSpeaking {
            ignoreFinishCallbacks = true
        }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
        isPaused = false
        verses.removeAll()
        currentIndex = 0
        onVerseCompletion = nil
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [self] in
            if ignoreFinishCallbacks {
                ignoreFinishCallbacks = false
                return
            }

            if currentIndex < verses.count {
                let verse = verses[currentIndex]
                onVerseCompletion?(verse)
                currentIndex += 1
                if currentIndex < verses.count {
                    speakCurrentVerse()
                } else {
                    isSpeaking = false
                }
            } else {
                isSpeaking = false
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        DispatchQueue.main.async { [self] in
            ignoreFinishCallbacks = false
            isSpeaking = false
        }
    }
}
