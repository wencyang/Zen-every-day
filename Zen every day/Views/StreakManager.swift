import SwiftUI
import Combine

// MARK: - Achievement Model
struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: AchievementRequirement
    var unlocked: Bool = false
    var unlockedDate: Date?
    var progress: Int = 0
    var maxProgress: Int
    
    enum AchievementRequirement: Codable {
        case streak(days: Int)
        case totalDays(count: Int)
        case quotesRead(count: Int)
        case meditationMinutes(minutes: Int)
        case savedQuotes(count: Int)
        case journalEntries(count: Int)
        case consecutiveWeeks(weeks: Int)
        case earlyBird(days: Int) // Read before 7 AM
        case nightOwl(days: Int)  // Read after 10 PM
        case perfectMonth
    }
    
    var progressPercentage: Double {
        guard maxProgress > 0 else { return 0 }
        return min(Double(progress) / Double(maxProgress), 1.0)
    }
    
    var isComplete: Bool {
        return progress >= maxProgress
    }
    
    var color: Color {
        switch requirement {
        case .streak: return .orange
        case .totalDays: return .blue
        case .quotesRead: return .purple
        case .meditationMinutes: return .green
        case .savedQuotes: return .yellow
        case .journalEntries: return .pink
        case .consecutiveWeeks: return .red
        case .earlyBird: return .cyan
        case .nightOwl: return .indigo
        case .perfectMonth: return .mint
        }
    }
}

// MARK: - Streak Manager
class StreakManager: ObservableObject {
    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var totalDaysRead: Int = 0
    @Published var totalQuotesRead: Int = 0
    @Published var totalMeditationMinutes: Int = 0
    @Published var achievements: [Achievement] = []
    @Published var recentlyUnlocked: Achievement?
    @Published var showAchievementUnlocked = false
    
    private let streakKey = "currentStreak"
    private let bestStreakKey = "bestStreak"
    private let lastReadDateKey = "lastReadDate"
    private let totalDaysKey = "totalDaysRead"
    private let totalQuotesKey = "totalQuotesRead"
    private let achievementsKey = "achievements"
    private let readDatesKey = "readDates"
    
    init() {
        loadData()
        initializeAchievements()
        checkTodayStreak()
    }
    
    // MARK: - Data Management
    
    private func loadData() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        bestStreak = UserDefaults.standard.integer(forKey: bestStreakKey)
        totalDaysRead = UserDefaults.standard.integer(forKey: totalDaysKey)
        totalQuotesRead = UserDefaults.standard.integer(forKey: totalQuotesKey)
        
        if let achievementsData = UserDefaults.standard.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: achievementsData) {
            achievements = decoded
        }
    }
    
    private func saveData() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(bestStreak, forKey: bestStreakKey)
        UserDefaults.standard.set(totalDaysRead, forKey: totalDaysKey)
        UserDefaults.standard.set(totalQuotesRead, forKey: totalQuotesKey)
        
        if let encoded = try? JSONEncoder().encode(achievements) {
            UserDefaults.standard.set(encoded, forKey: achievementsKey)
        }
    }
    
    // MARK: - Streak Management
    
    func markTodayAsRead() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastReadDate = UserDefaults.standard.object(forKey: lastReadDateKey) as? Date
        
        if let lastDate = lastReadDate {
            let daysDifference = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
            
            if daysDifference == 0 {
                // Already read today
                return
            } else if daysDifference == 1 {
                // Consecutive day
                currentStreak += 1
                totalDaysRead += 1
                if currentStreak > bestStreak {
                    bestStreak = currentStreak
                }
            } else {
                // Streak broken
                currentStreak = 1
                totalDaysRead += 1
            }
        } else {
            // First time
            currentStreak = 1
            totalDaysRead = 1
            bestStreak = 1
        }
        
        UserDefaults.standard.set(today, forKey: lastReadDateKey)
        
        // Save read dates for calendar view
        var readDates = getReadDates()
        readDates.append(today)
        saveReadDates(readDates)
        
        saveData()
        updateAchievementProgress()
        checkForUnlockedAchievements()
    }
    
    private func checkTodayStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastReadDate = UserDefaults.standard.object(forKey: lastReadDateKey) as? Date
        
        if let lastDate = lastReadDate {
            let daysDifference = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
            
            if daysDifference > 1 {
                // Streak broken - reset
                currentStreak = 0
                saveData()
            }
        }
    }
    
    func incrementQuotesRead() {
        totalQuotesRead += 1
        UserDefaults.standard.set(totalQuotesRead, forKey: totalQuotesKey)
        updateAchievementProgress()
        checkForUnlockedAchievements()
    }
    
    func addMeditationMinutes(_ minutes: Int) {
        totalMeditationMinutes += minutes
        UserDefaults.standard.set(totalMeditationMinutes, forKey: "totalMeditationMinutes")
        updateAchievementProgress()
        checkForUnlockedAchievements()
    }
    
    // MARK: - Calendar Support
    
    func getReadDates() -> [Date] {
        if let data = UserDefaults.standard.data(forKey: readDatesKey),
           let dates = try? JSONDecoder().decode([Date].self, from: data) {
            return dates
        }
        return []
    }
    
    private func saveReadDates(_ dates: [Date]) {
        if let encoded = try? JSONEncoder().encode(dates) {
            UserDefaults.standard.set(encoded, forKey: readDatesKey)
        }
    }
    
    func isDateRead(_ date: Date) -> Bool {
        let readDates = getReadDates()
        let targetDay = Calendar.current.startOfDay(for: date)
        return readDates.contains { Calendar.current.isDate($0, inSameDayAs: targetDay) }
    }
    
    // MARK: - Achievements
    
    private func initializeAchievements() {
        if achievements.isEmpty {
            achievements = [
                // Streak achievements
                Achievement(
                    id: "first_step",
                    title: "First Step",
                    description: "Start your mindfulness journey",
                    icon: "star.fill",
                    requirement: .streak(days: 1),
                    maxProgress: 1
                ),
                Achievement(
                    id: "week_warrior",
                    title: "Week Warrior",
                    description: "7 day reading streak",
                    icon: "flame.fill",
                    requirement: .streak(days: 7),
                    maxProgress: 7
                ),
                Achievement(
                    id: "fortnight_focus",
                    title: "Fortnight Focus",
                    description: "14 day reading streak",
                    icon: "flame.circle.fill",
                    requirement: .streak(days: 14),
                    maxProgress: 14
                ),
                Achievement(
                    id: "monthly_master",
                    title: "Monthly Master",
                    description: "30 day reading streak",
                    icon: "crown.fill",
                    requirement: .streak(days: 30),
                    maxProgress: 30
                ),
                Achievement(
                    id: "zen_master",
                    title: "Zen Master",
                    description: "100 day reading streak",
                    icon: "sparkles",
                    requirement: .streak(days: 100),
                    maxProgress: 100
                ),
                
                // Total days achievements
                Achievement(
                    id: "dedicated_reader",
                    title: "Dedicated Reader",
                    description: "Read wisdom for 50 total days",
                    icon: "book.fill",
                    requirement: .totalDays(count: 50),
                    maxProgress: 50
                ),
                Achievement(
                    id: "wisdom_seeker",
                    title: "Wisdom Seeker",
                    description: "Read wisdom for 100 total days",
                    icon: "book.circle.fill",
                    requirement: .totalDays(count: 100),
                    maxProgress: 100
                ),
                Achievement(
                    id: "enlightened",
                    title: "Enlightened",
                    description: "Read wisdom for 365 total days",
                    icon: "sun.max.fill",
                    requirement: .totalDays(count: 365),
                    maxProgress: 365
                ),
                
                // Quotes read achievements
                Achievement(
                    id: "curious_mind",
                    title: "Curious Mind",
                    description: "Read 25 quotes",
                    icon: "quote.bubble.fill",
                    requirement: .quotesRead(count: 25),
                    maxProgress: 25
                ),
                Achievement(
                    id: "knowledge_collector",
                    title: "Knowledge Collector",
                    description: "Read 100 quotes",
                    icon: "text.quote",
                    requirement: .quotesRead(count: 100),
                    maxProgress: 100
                ),
                Achievement(
                    id: "wisdom_library",
                    title: "Wisdom Library",
                    description: "Read 500 quotes",
                    icon: "books.vertical.fill",
                    requirement: .quotesRead(count: 500),
                    maxProgress: 500
                ),
                
                // Meditation achievements
                Achievement(
                    id: "meditation_beginner",
                    title: "Meditation Beginner",
                    description: "Meditate for 60 minutes total",
                    icon: "figure.mind.and.body",
                    requirement: .meditationMinutes(minutes: 60),
                    maxProgress: 60
                ),
                Achievement(
                    id: "peaceful_mind",
                    title: "Peaceful Mind",
                    description: "Meditate for 300 minutes total",
                    icon: "brain.head.profile",
                    requirement: .meditationMinutes(minutes: 300),
                    maxProgress: 300
                ),
                Achievement(
                    id: "meditation_master",
                    title: "Meditation Master",
                    description: "Meditate for 1000 minutes total",
                    icon: "infinity.circle.fill",
                    requirement: .meditationMinutes(minutes: 1000),
                    maxProgress: 1000
                ),
                
                // Special achievements
                Achievement(
                    id: "early_bird",
                    title: "Early Bird",
                    description: "Read wisdom before 7 AM for 7 days",
                    icon: "sunrise.fill",
                    requirement: .earlyBird(days: 7),
                    maxProgress: 7
                ),
                Achievement(
                    id: "night_owl",
                    title: "Night Owl",
                    description: "Read wisdom after 10 PM for 7 days",
                    icon: "moon.stars.fill",
                    requirement: .nightOwl(days: 7),
                    maxProgress: 7
                ),
                Achievement(
                    id: "perfect_month",
                    title: "Perfect Month",
                    description: "Read every day for an entire month",
                    icon: "calendar.badge.checkmark",
                    requirement: .perfectMonth,
                    maxProgress: 1
                )
            ]
            saveData()
        }
    }
    
    private func updateAchievementProgress() {
        for index in achievements.indices {
            switch achievements[index].requirement {
            case .streak(let days):
                achievements[index].progress = min(currentStreak, days)
                
            case .totalDays(let count):
                achievements[index].progress = min(totalDaysRead, count)
                
            case .quotesRead(let count):
                achievements[index].progress = min(totalQuotesRead, count)
                
            case .meditationMinutes(let minutes):
                achievements[index].progress = min(totalMeditationMinutes, minutes)
                
            case .savedQuotes(let count):
                let savedCount = UserDefaults.standard.integer(forKey: "totalSavedQuotes")
                achievements[index].progress = min(savedCount, count)
                
            case .journalEntries(let count):
                let journalCount = UserDefaults.standard.integer(forKey: "totalJournalEntries")
                achievements[index].progress = min(journalCount, count)
                
            case .consecutiveWeeks(let weeks):
                let consecutiveWeeks = currentStreak / 7
                achievements[index].progress = min(consecutiveWeeks, weeks)
                
            case .earlyBird(let days):
                let earlyBirdDays = UserDefaults.standard.integer(forKey: "earlyBirdDays")
                achievements[index].progress = min(earlyBirdDays, days)
                
            case .nightOwl(let days):
                let nightOwlDays = UserDefaults.standard.integer(forKey: "nightOwlDays")
                achievements[index].progress = min(nightOwlDays, days)
                
            case .perfectMonth:
                checkPerfectMonth(index: index)
            }
        }
    }
    
    private func checkPerfectMonth(index: Int) {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // Get all dates in current month
        let startOfMonth = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: 1))!
        let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
        let numberOfDays = range.count
        
        // Check if all days in month have been read
        let readDates = getReadDates()
        var daysReadThisMonth = 0
        
        for day in 1...numberOfDays {
            if let date = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: day)) {
                if readDates.contains(where: { calendar.isDate($0, inSameDayAs: date) }) {
                    daysReadThisMonth += 1
                }
            }
        }
        
        if daysReadThisMonth == numberOfDays {
            achievements[index].progress = 1
        }
    }
    
    private func checkForUnlockedAchievements() {
        var hasNewUnlock = false
        
        for index in achievements.indices {
            if !achievements[index].unlocked && achievements[index].isComplete {
                achievements[index].unlocked = true
                achievements[index].unlockedDate = Date()
                recentlyUnlocked = achievements[index]
                hasNewUnlock = true
                
                // Haptic feedback
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
        
        if hasNewUnlock {
            saveData()
            showAchievementUnlocked = true
        }
    }
    
    func markEarlyBird() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 7 {
            var earlyBirdDays = UserDefaults.standard.integer(forKey: "earlyBirdDays")
            earlyBirdDays += 1
            UserDefaults.standard.set(earlyBirdDays, forKey: "earlyBirdDays")
            updateAchievementProgress()
            checkForUnlockedAchievements()
        }
    }
    
    func markNightOwl() {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 22 {
            var nightOwlDays = UserDefaults.standard.integer(forKey: "nightOwlDays")
            nightOwlDays += 1
            UserDefaults.standard.set(nightOwlDays, forKey: "nightOwlDays")
            updateAchievementProgress()
            checkForUnlockedAchievements()
        }
    }
}

// MARK: - Streak Display View
struct StreakDisplayView: View {
    @ObservedObject var streakManager: StreakManager
    @State private var showingAchievements = false
    @State private var animateFlame = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Current streak
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .scaleEffect(animateFlame ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true),
                            value: animateFlame
                        )
                    
                    Text("\(streakManager.currentStreak)")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                
                Text("Day Streak")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Week view
            HStack(spacing: 6) {
                ForEach(0..<7) { dayOffset in
                    DayIndicator(
                        isCompleted: isDayCompleted(dayOffset),
                        isToday: dayOffset == 6
                    )
                }
            }
            
            Spacer()
            
            // Achievements button
            Button(action: { showingAchievements = true }) {
                VStack(spacing: 4) {
                    Image(systemName: "trophy.fill")
                        .foregroundColor(.yellow)
                    
                    Text("\(unlockedCount)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .sheet(isPresented: $showingAchievements) {
            AchievementsView(streakManager: streakManager)
        }
        .onAppear {
            if streakManager.currentStreak > 0 {
                animateFlame = true
            }
        }
    }
    
    private func isDayCompleted(_ dayOffset: Int) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        guard let date = calendar.date(byAdding: .day, value: dayOffset - 6, to: today) else {
            return false
        }
        return streakManager.isDateRead(date)
    }
    
    private var unlockedCount: Int {
        streakManager.achievements.filter { $0.unlocked }.count
    }
}

// MARK: - Day Indicator View
struct DayIndicator: View {
    let isCompleted: Bool
    let isToday: Bool
    
    var body: some View {
        Circle()
            .fill(fillColor)
            .frame(width: 12, height: 12)
            .overlay(
                Circle()
                    .stroke(isToday ? Color.blue : Color.clear, lineWidth: 2)
            )
    }
    
    private var fillColor: Color {
        if isCompleted {
            return .green
        } else if isToday {
            return .blue.opacity(0.3)
        } else {
            return .gray.opacity(0.3)
        }
    }
}

// MARK: - Achievements View
struct AchievementsView: View {
    @ObservedObject var streakManager: StreakManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedCategory: AchievementCategory = .all
    
    enum AchievementCategory: String, CaseIterable {
        case all = "All"
        case unlocked = "Unlocked"
        case inProgress = "In Progress"
        case locked = "Locked"
        
        var icon: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .unlocked: return "checkmark.circle.fill"
            case .inProgress: return "arrow.triangle.circlepath"
            case .locked: return "lock.fill"
            }
        }
    }
    
    var filteredAchievements: [Achievement] {
        switch selectedCategory {
        case .all:
            return streakManager.achievements
        case .unlocked:
            return streakManager.achievements.filter { $0.unlocked }
        case .inProgress:
            return streakManager.achievements.filter { !$0.unlocked && $0.progress > 0 }
        case .locked:
            return streakManager.achievements.filter { !$0.unlocked && $0.progress == 0 }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Category selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(AchievementCategory.allCases, id: \.self) { category in
                            CategoryChip(
                                category: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                // Achievements grid
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        ForEach(filteredAchievements) { achievement in
                            AchievementCard(achievement: achievement)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.large)
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

// MARK: - Category Chip View
struct CategoryChip: View {
    let category: AchievementsView.AchievementCategory
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(category.rawValue, systemImage: category.icon)
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color.gray.opacity(0.2))
                )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Achievement Card View
struct AchievementCard: View {
    let achievement: Achievement
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(achievement.unlocked ? achievement.color : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(achievement.unlocked ? .white : .gray)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            
            // Title
            Text(achievement.title)
                .font(.footnote.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            // Progress or unlock date
            if achievement.unlocked {
                if let date = achievement.unlockedDate {
                    Text(date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                // Progress bar
                ProgressView(value: achievement.progressPercentage)
                    .progressViewStyle(LinearProgressViewStyle(tint: achievement.color))
                    .frame(height: 4)
                
                Text("\(achievement.progress)/\(achievement.maxProgress)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(achievement.unlocked ? 
                     achievement.color.opacity(0.1) : 
                     Color.gray.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(achievement.unlocked ? 
                       achievement.color.opacity(0.3) : 
                       Color.gray.opacity(0.2), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Achievement Unlocked Popup
struct AchievementUnlockedView: View {
    let achievement: Achievement
    @Binding var isShowing: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        if isShowing {
            VStack(spacing: 16) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                
                Text("Achievement Unlocked!")
                    .font(.title2.bold())
                
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(achievement.color)
                
                Text(achievement.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(achievement.color.opacity(0.5), lineWidth: 2)
            )
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                    scale = 1.0
                    opacity = 1.0
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        opacity = 0
                        scale = 0.8
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShowing = false
                    }
                }
            }
        }
    }
}