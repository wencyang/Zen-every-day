import SwiftUI
import AVFoundation
import Combine

// MARK: - Meditation Session Model
class MeditationSession: ObservableObject {
    @Published var duration: TimeInterval = 300 // 5 minutes default
    @Published var isActive = false
    @Published var isPaused = false
    @Published var timeRemaining: TimeInterval = 0
    @Published var selectedSound: AmbientSound = .silence
    @Published var showCompletionView = false
    
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var completionPlayer: AVAudioPlayer?
    
    enum AmbientSound: String, CaseIterable {
        case silence = "Silence"
        case rain = "Rain"
        case forest = "Forest"
        case ocean = "Ocean Waves"
        case tibetanBowl = "Tibetan Bowl"
        case whiteNoise = "White Noise"
        
        var systemImage: String {
            switch self {
            case .silence: return "speaker.slash"
            case .rain: return "cloud.rain"
            case .forest: return "leaf"
            case .ocean: return "water.waves"
            case .tibetanBowl: return "bell"
            case .whiteNoise: return "waveform"
            }
        }
        
        var fileName: String {
            switch self {
            case .silence: return ""
            case .rain: return "rain_ambient"
            case .forest: return "forest_ambient"
            case .ocean: return "ocean_ambient"
            case .tibetanBowl: return "tibetan_bowl"
            case .whiteNoise: return "white_noise"
            }
        }
    }
    
    let presetDurations: [TimeInterval] = [
        60,    // 1 minute
        180,   // 3 minutes
        300,   // 5 minutes
        600,   // 10 minutes
        900,   // 15 minutes
        1200,  // 20 minutes
        1800,  // 30 minutes
        2700,  // 45 minutes
        3600   // 60 minutes
    ]
    
    func startMeditation() {
        isActive = true
        isPaused = false
        timeRemaining = duration
        playAmbientSound()
        startTimer()
        
        // Log meditation start
        logMeditationStart()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func pauseMeditation() {
        isPaused = true
        timer?.invalidate()
        audioPlayer?.pause()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func resumeMeditation() {
        isPaused = false
        audioPlayer?.play()
        startTimer()
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func endMeditation() {
        timer?.invalidate()
        audioPlayer?.stop()
        audioPlayer = nil
        
        if timeRemaining < duration {
            // Only log if actually meditated
            let actualDuration = duration - timeRemaining
            logMeditationSession(duration: actualDuration)
            
            // Play completion sound
            playCompletionSound()
            
            // Show completion view
            showCompletionView = true
        }
        
        isActive = false
        isPaused = false
        timeRemaining = 0
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            if self.timeRemaining > 0 {
                self.timeRemaining -= 1
            } else {
                self.endMeditation()
            }
        }
    }
    
    private func playAmbientSound() {
        guard selectedSound != .silence,
              !selectedSound.fileName.isEmpty else { return }
        
        guard let soundAsset = NSDataAsset(name: selectedSound.fileName) else {
            debugLog("Could not load ambient sound: \(selectedSound.fileName)")
            return
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: soundAsset.data)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
            
            // Fade in
            audioPlayer?.setVolume(0.5, fadeDuration: 2.0)
        } catch {
            debugLog("Error playing ambient sound: \(error)")
        }
    }
    
    private func playCompletionSound() {
        guard let soundAsset = NSDataAsset(name: "meditation_bell") else {
            debugLog("Could not load completion sound")
            return
        }
        
        do {
            completionPlayer = try AVAudioPlayer(data: soundAsset.data)
            completionPlayer?.volume = 0.7
            completionPlayer?.play()
        } catch {
            debugLog("Error playing completion sound: \(error)")
        }
    }
    
    private func logMeditationStart() {
        // Analytics or logging
        debugLog("Meditation started: \(duration) seconds with \(selectedSound.rawValue)")
    }
    
    private func logMeditationSession(duration: TimeInterval) {
        // Save to UserDefaults or Core Data
        var sessions = getMeditationHistory()
        let session = MeditationRecord(
            date: Date(),
            duration: duration,
            ambientSound: selectedSound.rawValue
        )
        sessions.append(session)
        saveMeditationHistory(sessions)
        
        debugLog("Meditation completed: \(duration) seconds")
    }
    
    private func getMeditationHistory() -> [MeditationRecord] {
        if let data = UserDefaults.standard.data(forKey: "meditationHistory"),
           let sessions = try? JSONDecoder().decode([MeditationRecord].self, from: data) {
            return sessions
        }
        return []
    }
    
    private func saveMeditationHistory(_ sessions: [MeditationRecord]) {
        if let data = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(data, forKey: "meditationHistory")
        }
    }
}

// MARK: - Meditation Record Model
struct MeditationRecord: Codable {
    let date: Date
    let duration: TimeInterval
    let ambientSound: String
}

// MARK: - Main Meditation Timer View
struct MeditationTimerView: View {
    @StateObject private var session = MeditationSession()
    @State private var showingDurationPicker = false
    @State private var showingSoundPicker = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(UIColor.systemBackground),
                    Color(UIColor.systemBackground).opacity(0.95)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            if session.isActive {
                ActiveMeditationView(session: session)
            } else {
                MeditationSetupView(
                    session: session,
                    showingDurationPicker: $showingDurationPicker,
                    showingSoundPicker: $showingSoundPicker
                )
            }
        }
        .sheet(isPresented: $showingDurationPicker) {
            DurationPickerView(session: session)
        }
        .sheet(isPresented: $showingSoundPicker) {
            SoundPickerView(session: session)
        }
        .sheet(isPresented: $session.showCompletionView) {
            MeditationCompletionView(session: session)
        }
    }
}

// MARK: - Setup View
struct MeditationSetupView: View {
    @ObservedObject var session: MeditationSession
    @Binding var showingDurationPicker: Bool
    @Binding var showingSoundPicker: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            // Title
            VStack(spacing: 8) {
                Image(systemName: "figure.mind.and.body")
                    .font(.system(size: 50))
                    .foregroundStyle(.tint)
                
                Text("Meditation Timer")
                    .font(.largeTitle.bold())
                
                Text("Find your inner peace")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            
            Spacer()
            
            // Duration selector
            VStack(spacing: 12) {
                Text("Duration")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button(action: { showingDurationPicker = true }) {
                    HStack {
                        Image(systemName: "clock")
                        Text(formatDuration(session.duration))
                            .font(.title2.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)
            }
            
            // Sound selector
            VStack(spacing: 12) {
                Text("Ambient Sound")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Button(action: { showingSoundPicker = true }) {
                    HStack {
                        Image(systemName: session.selectedSound.systemImage)
                        Text(session.selectedSound.rawValue)
                            .font(.title2.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.ultraThinMaterial)
                    )
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            // Start button
            Button(action: { session.startMeditation() }) {
                Label("Start Meditation", systemImage: "play.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.tint)
                    )
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            
            // Quick presets
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach([60, 180, 300, 600, 900], id: \.self) { duration in
                        Button(action: {
                            session.duration = TimeInterval(duration)
                        }) {
                            Text(formatDurationShort(TimeInterval(duration)))
                                .font(.footnote.bold())
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(session.duration == TimeInterval(duration) ? Color.tint : Color.gray.opacity(0.2))
                                )
                                .foregroundColor(session.duration == TimeInterval(duration) ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        if minutes < 60 {
            return "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours) hour\(hours > 1 ? "s" : "")"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    private func formatDurationShort(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}

// MARK: - Active Meditation View
struct ActiveMeditationView: View {
    @ObservedObject var session: MeditationSession
    @State private var breathPhase = false
    
    var body: some View {
        VStack(spacing: 40) {
            // Close button
            HStack {
                Spacer()
                Button(action: {
                    session.endMeditation()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
            Spacer()
            
            // Timer circle
            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                    .frame(width: 250, height: 250)
                
                // Progress circle
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 250, height: 250)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: progress)
                
                // Breathing circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.blue.opacity(0.3), .clear],
                            center: .center,
                            startRadius: 20,
                            endRadius: breathPhase ? 100 : 80
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(breathPhase ? 1.1 : 0.9)
                    .animation(
                        .easeInOut(duration: 4)
                        .repeatForever(autoreverses: true),
                        value: breathPhase
                    )
                
                // Time display
                VStack(spacing: 8) {
                    Text(formatTime(session.timeRemaining))
                        .font(.system(size: 48, weight: .light, design: .rounded))
                        .monospacedDigit()
                    
                    Text("remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Breathing guide
            Text(breathPhase ? "Breathe In" : "Breathe Out")
                .font(.title3)
                .foregroundColor(.secondary)
                .animation(.easeInOut(duration: 4), value: breathPhase)
            
            Spacer()
            
            // Control buttons
            HStack(spacing: 40) {
                // Pause/Resume button
                Button(action: {
                    if session.isPaused {
                        session.resumeMeditation()
                    } else {
                        session.pauseMeditation()
                    }
                }) {
                    Image(systemName: session.isPaused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.tint)
                }
                
                // End button
                Button(action: {
                    session.endMeditation()
                }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
        }
        .onAppear {
            breathPhase = true
        }
    }
    
    private var progress: CGFloat {
        guard session.duration > 0 else { return 0 }
        return CGFloat(session.timeRemaining / session.duration)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Duration Picker View
struct DurationPickerView: View {
    @ObservedObject var session: MeditationSession
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedMinutes: Int = 5
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("Duration", selection: $selectedMinutes) {
                    ForEach(1...60, id: \.self) { minute in
                        Text("\(minute) min").tag(minute)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 200)
                
                Spacer()
            }
            .navigationTitle("Select Duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        session.duration = TimeInterval(selectedMinutes * 60)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            selectedMinutes = Int(session.duration) / 60
        }
    }
}

// MARK: - Sound Picker View
struct SoundPickerView: View {
    @ObservedObject var session: MeditationSession
    @Environment(\.presentationMode) var presentationMode
    @State private var playingSample: MeditationSession.AmbientSound?
    private var samplePlayer: AVAudioPlayer?
    
    var body: some View {
        NavigationView {
            List {
                ForEach(MeditationSession.AmbientSound.allCases, id: \.self) { sound in
                    Button(action: {
                        session.selectedSound = sound
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Image(systemName: sound.systemImage)
                                .frame(width: 30)
                                .foregroundColor(.tint)
                            
                            Text(sound.rawValue)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if session.selectedSound == sound {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.tint)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Ambient Sound")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Completion View
struct MeditationCompletionView: View {
    @ObservedObject var session: MeditationSession
    @Environment(\.presentationMode) var presentationMode
    @State private var showingConfetti = false
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Celebration icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .scaleEffect(showingConfetti ? 1.1 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: showingConfetti)
            
            VStack(spacing: 12) {
                Text("Well Done!")
                    .font(.largeTitle.bold())
                
                Text("You completed your meditation")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            
            // Stats
            VStack(spacing: 20) {
                HStack {
                    Label("\(Int(session.duration / 60)) minutes", systemImage: "clock")
                    Spacer()
                    Label(session.selectedSound.rawValue, systemImage: session.selectedSound.systemImage)
                }
                .font(.headline)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.tint)
                    )
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            withAnimation {
                showingConfetti = true
            }
        }
    }
}