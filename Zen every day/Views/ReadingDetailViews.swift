// MARK: - Fixed Reading Detail View
import SwiftUI

struct ReadingDetailView: View {
    let initialReading: DailyReading
    let plan: ReadingPlan
    @EnvironmentObject var plansManager: ReadingPlansManager
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var savedVersesManager: SavedVersesManager
    @ObservedObject private var verseSpeaker = VerseSpeaker.shared
    
    @State private var currentReading: DailyReading
    @State private var verses: [Verse] = []
    @State private var completedVerses: Set<String> = []
    @State private var isLoading = true
    @State private var selectedVerseForCard: Verse?
    @State private var showCopyToast = false
    @State private var showCompletionCelebration = false
    @State private var previousDayCompleted = false
    @State private var speechIndex: Int = 0
    
    private let bibleManager = BibleManager.shared
    
    init(reading: DailyReading, plan: ReadingPlan) {
        self.initialReading = reading
        self.plan = plan
        self._currentReading = State(initialValue: reading)
    }
    
    // Current day completion status
    private var isDayCompleted: Bool {
        completedVerses.count == verses.count && !verses.isEmpty
    }
    
    // Get next available day
    private var nextReading: DailyReading? {
        plansManager.getNextUnreadDay(for: plan.id)
    }
    
    // Check if there's a previous day before current
    private var hasPreviousDay: Bool {
        guard let activePlan = plansManager.activePlans.first(where: { $0.id == plan.id }) else { return false }
        return activePlan.readings.contains { $0.day < currentReading.day }
    }
    
    // Check if there's a next day after current
    private var hasNextDay: Bool {
        guard let activePlan = plansManager.activePlans.first(where: { $0.id == plan.id }) else { return false }
        return activePlan.readings.contains { $0.day > currentReading.day }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with current day info
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Day \(currentReading.day)")
                            .font(.caption)
                            .foregroundColor(plan.color.color)
                            .fontWeight(.semibold)
                        
                        Text(currentReading.title)
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        // Current day completion status
                        HStack {
                            Image(systemName: isDayCompleted ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isDayCompleted ? .green : .secondary)
                            Text(isDayCompleted ? "Complete" : "In Progress")
                                .font(.caption)
                                .foregroundColor(isDayCompleted ? .green : .secondary)
                        }
                    }
                }
                
                // Progress bar for CURRENT DAY ONLY
                VStack(spacing: 8) {
                    HStack {
                        Text("Today's Progress")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text("\(completedVerses.count) of \(verses.count) verses")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if !verses.isEmpty {
                        ProgressView(value: Double(completedVerses.count), total: Double(verses.count))
                            .tint(plan.color.color)
                            .animation(.easeInOut(duration: 0.5), value: completedVerses.count)
                    }
                }
                
                // References for CURRENT DAY
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(currentReading.references) { reference in
                            ReferenceChip(
                                reference: reference,
                                plan: plan,
                                isCompleted: isReferenceCompleted(reference)
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        plan.color.color.opacity(0.05),
                        Color(.systemGroupedBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            
            Divider()
            
            // Content for CURRENT DAY
            if isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Loading verses...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 100)
            } else if verses.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)
                    
                    Text("Verses Not Found")
                        .font(.headline)
                    
                    Text("Could not load verses for Day \(currentReading.day)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 100)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        ForEach(verses) { verse in
                            VerseCompletionCard(
                                verse: verse,
                                plan: plan,
                                isCompleted: completedVerses.contains(verse.id),
                                onToggleComplete: {
                                    toggleVerseCompletion(verse)
                                },
                                onShare: {
                                    selectedVerseForCard = verse
                                },
                                onBookmark: {
                                    savedVersesManager.toggleVerseSaved(verse)
                                },
                                showCopyToast: $showCopyToast
                            )
                            .environmentObject(settings)
                            .environmentObject(savedVersesManager)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if hasPreviousDay {
                    Button(action: {
                        navigateToPreviousDay()
                    }) {
                        HStack {
                            Image(systemName: "arrow.left")
                            Text("Previous")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }
            }
            
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button(action: {
                    toggleSpeech()
                }) {
                    Image(systemName: verseSpeaker.isSpeaking ? "pause.fill" : (verseSpeaker.isPaused ? "play.fill" : "speaker.wave.2.fill"))
                }

                Button(action: {
                    startSpeechFromBeginning()
                }) {
                    Image(systemName: "gobackward")
                }

                if hasNextDay {
                    Button(action: {
                        navigateToNextDay()
                    }) {
                        HStack {
                            Text("Next Day")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .toast(
            isShowing: $showCopyToast,
            message: "Verse Copied",
            icon: "doc.on.doc.fill",
            color: .green,
            duration: 1.2
        )
        .sheet(item: $selectedVerseForCard) { verse in
            VerseCardCreator(verse: verse)
        }
        .overlay(
            Group {
                if showCompletionCelebration {
                    CompletionCelebrationView(
                        plan: plan,
                        currentDay: currentReading.day,
                        hasNextDay: hasNextDay,
                        onContinueToNext: {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showCompletionCelebration = false
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                navigateToNextDay()
                            }
                        },
                        onStayAndReflect: {
                            withAnimation(.easeOut(duration: 0.5)) {
                                showCompletionCelebration = false
                            }
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
        )
        .onAppear {
            loadCurrentDayData()
        }
        .onChange(of: completedVerses) { _, newValue in
            handleDayCompletionChange(newValue)
        }
        .onDisappear {
            speechIndex = verseSpeaker.currentVerseIndex
            saveSpeechIndex()
            verseSpeaker.stop()
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleVerseCompletion(_ verse: Verse) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if completedVerses.contains(verse.id) {
                completedVerses.remove(verse.id)
            } else {
                completedVerses.insert(verse.id)
            }
        }
        saveCompletedVerses()
    }

    private func markVerseCompleted(_ verse: Verse) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            completedVerses.insert(verse.id)
        }
        saveCompletedVerses()
    }
    
    private func handleDayCompletionChange(_ newValue: Set<String>) {
        let nowCompleted = newValue.count == verses.count && !verses.isEmpty

        // During initial load, just set the baseline state
        if isLoading {
            previousDayCompleted = nowCompleted
            return
        }

        // Show celebration when transitioning from incomplete to complete
        if nowCompleted && !previousDayCompleted {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showCompletionCelebration = true
            }

            // Mark day as complete in plan manager
            plansManager.markDayCompleted(planId: plan.id, day: currentReading.day)
        }

        // If went from complete to incomplete, mark day as incomplete
        if previousDayCompleted && !nowCompleted {
            plansManager.markDayIncomplete(planId: plan.id, day: currentReading.day)
        }

        previousDayCompleted = nowCompleted
    }
    
    private func navigateToNextDay() {
        guard let activePlan = plansManager.activePlans.first(where: { $0.id == plan.id }) else { return }
        
        // Find next day after current
        if let nextDay = activePlan.readings.first(where: { $0.day > currentReading.day }) {
            navigateToDay(nextDay)
        }
    }
    
    private func navigateToPreviousDay() {
        guard let activePlan = plansManager.activePlans.first(where: { $0.id == plan.id }) else { return }
        
        // Find previous day before current
        if let previousDay = activePlan.readings.filter({ $0.day < currentReading.day }).max(by: { $0.day < $1.day }) {
            navigateToDay(previousDay)
        }
    }
    
    private func navigateToDay(_ newReading: DailyReading) {
        // Save progress for the current day and stop any ongoing speech
        speechIndex = verseSpeaker.currentVerseIndex
        saveSpeechIndex()
        verseSpeaker.stop()

        // Update to new day
        currentReading = newReading

        // Reset speech index until we load the saved value for the new day
        speechIndex = 0
        
        // Reset state for new day
        completedVerses.removeAll()
        verses.removeAll()
        isLoading = true
        
        // Load new day's data
        loadCurrentDayData()
    }
    
    private func isReferenceCompleted(_ reference: VerseReference) -> Bool {
        let referenceVerses = verses.filter { verse in
            verse.book_name == reference.bookName &&
            verse.chapter == reference.chapter &&
            verse.verse >= reference.startVerse &&
            verse.verse <= reference.endVerse
        }
        
        return !referenceVerses.isEmpty && referenceVerses.allSatisfy { completedVerses.contains($0.id) }
    }
    
    private func loadCurrentDayData() {
        loadCompletedVerses()
        loadSpeechIndex()
        loadVerses()
    }

    private func toggleSpeech() {
        if verseSpeaker.isSpeaking {
            verseSpeaker.pause()
            speechIndex = verseSpeaker.currentVerseIndex
            saveSpeechIndex()
        } else if verseSpeaker.isPaused {
            verseSpeaker.resume()
        } else {
            verseSpeaker.speak(verses: verses, startAt: speechIndex) { verse in
                markVerseCompleted(verse)
                speechIndex = verseSpeaker.currentVerseIndex
                saveSpeechIndex()
            }
        }
    }

    private func startSpeechFromBeginning() {
        speechIndex = 0
        saveSpeechIndex()
        verseSpeaker.stop()
        verseSpeaker.speak(verses: verses, startAt: speechIndex) { verse in
            markVerseCompleted(verse)
            speechIndex = verseSpeaker.currentVerseIndex
            saveSpeechIndex()
        }
    }
    
    private func saveCompletedVerses() {
        let key = "completed_verses_\(plan.id)_\(currentReading.day)"
        let data = Array(completedVerses)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func loadCompletedVerses() {
        let key = "completed_verses_\(plan.id)_\(currentReading.day)"
        if let data = UserDefaults.standard.array(forKey: key) as? [String] {
            completedVerses = Set(data)
        } else {
            completedVerses.removeAll()
        }
        previousDayCompleted = isDayCompleted
    }

    private func saveSpeechIndex() {
        let key = "speech_index_\(plan.id)_\(currentReading.day)"
        UserDefaults.standard.set(speechIndex, forKey: key)
    }

    private func loadSpeechIndex() {
        let key = "speech_index_\(plan.id)_\(currentReading.day)"
        speechIndex = UserDefaults.standard.integer(forKey: key)
    }
    
    // Verse loading methods
    private func loadVerses() {
        guard bibleManager.isLoaded else {
            waitForBibleAndLoad()
            return
        }
        performVerseLoading()
    }
    
    private func waitForBibleAndLoad() {
        if bibleManager.isLoading {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.waitForBibleAndLoad()
            }
            return
        }
        
        if bibleManager.isLoaded {
            performVerseLoading()
        } else {
            isLoading = false
        }
    }
    
    private func performVerseLoading() {
        DispatchQueue.global(qos: .userInitiated).async {
            var loadedVerses: [Verse] = []
            
            for reference in currentReading.references {
                let versesForRef = loadVersesForReference(reference)
                loadedVerses.append(contentsOf: versesForRef)
            }
            
            DispatchQueue.main.async {
                self.verses = loadedVerses
                self.isLoading = false
                self.previousDayCompleted = self.isDayCompleted
            }
        }
    }
    
    private func loadVersesForReference(_ reference: VerseReference) -> [Verse] {
        var verses: [Verse] = []
        
        for verseNum in reference.startVerse...reference.endVerse {
            if let verse = bibleManager.findVerse(
                bookName: reference.bookName,
                chapter: reference.chapter,
                verseNumber: verseNum
            ) {
                verses.append(verse)
            }
            
            if verses.count >= 100 {
                break
            }
        }
        
        return verses
    }
}

// MARK: - Reference Chip Component
struct ReferenceChip: View {
    let reference: VerseReference
    let plan: ReadingPlan
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 12))
                .foregroundColor(isCompleted ? .white : plan.color.color)
            
            Text(reference.displayText)
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(isCompleted ? .white : plan.color.color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isCompleted ? Color.green : plan.color.color.opacity(0.1))
        )
        .overlay(
            Capsule()
                .stroke(isCompleted ? Color.green : plan.color.color, lineWidth: 1)
        )
        .animation(.easeInOut(duration: 0.3), value: isCompleted)
    }
}

// MARK: - Verse Completion Card
struct VerseCompletionCard: View {
    let verse: Verse
    let plan: ReadingPlan
    let isCompleted: Bool
    let onToggleComplete: () -> Void
    let onShare: () -> Void
    let onBookmark: () -> Void

    @Binding var showCopyToast: Bool

    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var savedVersesManager: SavedVersesManager
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            // Trigger the zoom animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            // Complete the action and reset
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                onToggleComplete()
                withAnimation(.easeOut(duration: 0.2)) {
                    isPressed = false
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Header with reference and actions
                HStack(alignment: .center) {
                    HStack(spacing: 12) {
                        // Completion indicator (starts empty)
                        ZStack {
                            Circle()
                                .strokeBorder(
                                    isCompleted ? plan.color.color : Color(.systemGray4),
                                    lineWidth: 2
                                )
                                .background(
                                    Circle()
                                        .fill(isCompleted ? plan.color.color : Color.clear)
                                )
                                .frame(width: 24, height: 24)
                            
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .scaleEffect(isPressed ? 1.3 : 1.0)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
                            }
                        }
                        .scaleEffect(isPressed ? 1.2 : 1.0)
                        
                        Text("\(verse.book_name) \(verse.chapter):\(verse.verse)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(isCompleted ? .secondary : plan.color.color)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        // Share button
                        Button(action: onShare) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Copy button
                        Button(action: {
                            let copyText = "\(verse.text.cleanVerse)\n\(verse.book_name) \(verse.chapter):\(verse.verse)"
                            UIPasteboard.general.string = copyText
                            showCopyToast = true
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())

                        // Bookmark button
                        Button(action: onBookmark) {
                            Image(
                                systemName: savedVersesManager.isVerseSaved(verse)
                                    ? "bookmark.fill" : "bookmark"
                            )
                            .font(.system(size: 16))
                            .foregroundColor(
                                savedVersesManager.isVerseSaved(verse) ? .blue : .secondary
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Verse text
                Text(verse.text.cleanVerse)
                    .font(.system(size: settings.fontSize))
                    .foregroundColor(isCompleted ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(4)
                    .animation(.easeInOut(duration: 0.3), value: isCompleted)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isCompleted ? Color(.systemGray6) : Color(.secondarySystemGroupedBackground))
                    .animation(.easeInOut(duration: 0.3), value: isCompleted)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isCompleted ? plan.color.color.opacity(0.3) : Color.clear,
                        lineWidth: 1
                    )
                    .animation(.easeInOut(duration: 0.3), value: isCompleted)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(
                color: isCompleted ? plan.color.color.opacity(0.2) : Color.clear,
                radius: isCompleted ? 4 : 0,
                x: 0,
                y: 2
            )
            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: isCompleted)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Completion Celebration View
struct CompletionCelebrationView: View {
    let plan: ReadingPlan
    let currentDay: Int
    let hasNextDay: Bool
    let onContinueToNext: () -> Void
    let onStayAndReflect: () -> Void
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated completion icon
            ZStack {
                Circle()
                    .fill(plan.color.color)
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseScale)
                    .onAppear {
                        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                            pulseScale = 1.1
                        }
                    }
                
                Image(systemName: "checkmark")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 12) {
                Text("Day \(currentDay) Complete! 🎉")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Excellent work reading today's verses")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Action buttons
            VStack(spacing: 12) {
                // Continue to next day button (only if there is a next day)
                if hasNextDay {
                    Button(action: onContinueToNext) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Continue to Day \(currentDay + 1)")
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(plan.color.color)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Stay and reflect button
                Button(action: onStayAndReflect) {
                    HStack {
                        Image(systemName: "heart.fill")
                        Text(hasNextDay ? "Stay & Reflect" : "Finish Reading")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(plan.color.color)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(plan.color.color, lineWidth: 2)
                            .fill(Color(.systemBackground))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: plan.color.color.opacity(0.3), radius: 20)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            plan.color.color.opacity(0.6),
                            plan.color.color.opacity(0.2)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
}
