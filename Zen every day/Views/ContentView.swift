import SwiftUI

struct ContentView: View {
    @StateObject private var dailyWisdomManager = DailyWisdomManager()
    @StateObject private var prayerManager = PrayerManager()
    @StateObject private var streakManager = StreakManager()
    @StateObject private var meditationSession = MeditationSession()
    
    @EnvironmentObject var settings: UserSettings
    @EnvironmentObject var activityManager: ReadingActivityManager
    @EnvironmentObject var savedQuotesManager: SavedQuotesManager
    @EnvironmentObject var notificationManager: NotificationManager
    @EnvironmentObject var backgroundManager: BackgroundImageManager
    @EnvironmentObject var musicManager: BackgroundMusicManager
    
    @State private var selectedTab = 0
    @State private var showingOnboarding = false
    @State private var hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    
    var body: some View {
        ZStack {
            // Background
            BackgroundView()
            
            // Main content
            TabView(selection: $selectedTab) {
                // Home Tab - Daily Wisdom
                HomeView(
                    dailyWisdomManager: dailyWisdomManager,
                    streakManager: streakManager
                )
                .tabItem {
                    Label("Today", systemImage: "sun.max.fill")
                }
                .tag(0)
                
                // Explore Tab - Browse Quotes
                ExploreView(streakManager: streakManager)
                    .tabItem {
                        Label("Explore", systemImage: "books.vertical")
                    }
                    .tag(1)
                
                // Meditation Tab
                MeditationTimerView()
                    .tabItem {
                        Label("Meditate", systemImage: "figure.mind.and.body")
                    }
                    .tag(2)
                
                // Saved Tab
                SavedView()
                    .tabItem {
                        Label("Saved", systemImage: "bookmark.fill")
                    }
                    .tag(3)
                
                // Profile Tab
                ProfileView(
                    streakManager: streakManager,
                    prayerManager: prayerManager
                )
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(4)
            }
            .accentColor(.blue)
            
            // Achievement popup overlay
            if streakManager.showAchievementUnlocked,
               let achievement = streakManager.recentlyUnlocked {
                AchievementUnlockedView(
                    achievement: achievement,
                    isShowing: $streakManager.showAchievementUnlocked
                )
                .zIndex(100)
                .transition(.opacity.combined(with: .scale))
            }
        }
        .onAppear {
            setupApp()
        }
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(hasCompletedOnboarding: $hasSeenOnboarding)
                .onDisappear {
                    UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
                }
        }
    }
    
    private func setupApp() {
        // Show onboarding for first-time users
        if !hasSeenOnboarding {
            showingOnboarding = true
        }
        
        // Mark today as read
        streakManager.markTodayAsRead()
        
        // Check time-based achievements
        streakManager.markEarlyBird()
        streakManager.markNightOwl()
        
        // Start background music if enabled
        musicManager.startIfNeeded()
    }
}

// MARK: - Home View
struct HomeView: View {
    @ObservedObject var dailyWisdomManager: DailyWisdomManager
    @ObservedObject var streakManager: StreakManager
    @State private var refreshing = false
    @State private var showingCalendar = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Streak display
                    StreakDisplayView(streakManager: streakManager)
                        .padding(.horizontal)
                    
                    // Daily quote
                    if let quote = dailyWisdomManager.dailyQuote {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Daily Wisdom", systemImage: "quote.bubble.fill")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(Date(), style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            FloatingQuoteView(quote: quote)
                        }
                        .padding(.horizontal)
                    } else if let error = dailyWisdomManager.errorMessage {
                        ErrorView(message: error)
                            .padding()
                    } else {
                        ProgressView("Loading wisdom...")
                            .padding()
                    }
                    
                    // Quick actions
                    QuickActionsGrid()
                        .padding(.horizontal)
                    
                    // Recent reflections preview
                    RecentReflectionsView()
                        .padding(.horizontal)
                    
                    Spacer(minLength: 100)
                }
                .padding(.top)
            }
            .refreshable {
                await refreshContent()
            }
            .navigationTitle("Zen Every Day")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCalendar = true }) {
                        Image(systemName: "calendar")
                    }
                }
            }
            .sheet(isPresented: $showingCalendar) {
                CalendarView(streakManager: streakManager)
            }
        }
    }
    
    @MainActor
    private func refreshContent() async {
        refreshing = true
        
        // Simulate refresh
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Reload wisdom if needed
        WisdomManager.shared.loadWisdomIfNeeded()
        
        refreshing = false
    }
}

// MARK: - Quick Actions Grid
struct QuickActionsGrid: View {
    @State private var showingMeditation = false
    @State private var showingJournal = false
    @State private var showingBreathing = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                QuickActionCard(
                    icon: "figure.mind.and.body",
                    title: "Meditate",
                    subtitle: "5 min",
                    color: .green,
                    action: { showingMeditation = true }
                )
                
                QuickActionCard(
                    icon: "pencil.line",
                    title: "Journal",
                    subtitle: "Reflect",
                    color: .purple,
                    action: { showingJournal = true }
                )
                
                QuickActionCard(
                    icon: "wind",
                    title: "Breathe",
                    subtitle: "Relax",
                    color: .blue,
                    action: { showingBreathing = true }
                )
                
                QuickActionCard(
                    icon: "moon.stars",
                    title: "Sleep",
                    subtitle: "Stories",
                    color: .indigo,
                    action: { }
                )
            }
        }
        .sheet(isPresented: $showingMeditation) {
            MeditationTimerView()
        }
        .sheet(isPresented: $showingJournal) {
            JournalView()
        }
        .sheet(isPresented: $showingBreathing) {
            BreathingExerciseView()
        }
    }
}

// MARK: - Quick Action Card
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(color.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.spring(response: 0.3)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Recent Reflections View
struct RecentReflectionsView: View {
    @State private var reflections: [ReflectionEntry] = []
    
    var body: some View {
        if !reflections.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Recent Reflections", systemImage: "text.quote")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    NavigationLink(destination: AllReflectionsView()) {
                        Text("See All")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                VStack(spacing: 8) {
                    ForEach(reflections.prefix(2)) { reflection in
                        ReflectionCard(reflection: reflection)
                    }
                }
            }
            .onAppear {
                loadReflections()
            }
        }
    }
    
    private func loadReflections() {
        if let data = UserDefaults.standard.data(forKey: "reflectionHistory"),
           let decoded = try? JSONDecoder().decode([ReflectionEntry].self, from: data) {
            reflections = decoded.sorted { $0.date > $1.date }
        }
    }
}

// MARK: - Reflection Card
struct ReflectionCard: View {
    let reflection: ReflectionEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let mood = reflection.mood {
                    Text(mood)
                        .font(.caption)
                }
                
                Text(reflection.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(reflection.reflection)
                .font(.subheadline)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            if !reflection.gratitudes.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.pink)
                    
                    Text("\(reflection.gratitudes.count) gratitudes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// MARK: - Explore View
struct ExploreView: View {
    @ObservedObject var streakManager: StreakManager
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    @State private var quotes: [WisdomQuote] = []
    
    let categories = ["All", "Mindfulness", "Compassion", "Wisdom", "Peace", "Gratitude"]
    
    var filteredQuotes: [WisdomQuote] {
        let searchFiltered = searchText.isEmpty ? quotes : quotes.filter {
            $0.text.localizedCaseInsensitiveContains(searchText) ||
            ($0.author?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
        
        if selectedCategory == "All" {
            return searchFiltered
        } else {
            return searchFiltered.filter { quote in
                quote.tags?.contains(selectedCategory.lowercased()) ?? false
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search quotes...", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.1))
                )
                .padding(.horizontal)
                .padding(.top)
                
                // Category filter
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(categories, id: \.self) { category in
                            CategoryPill(
                                title: category,
                                isSelected: selectedCategory == category,
                                action: { selectedCategory = category }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
                
                // Quotes list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredQuotes) { quote in
                            EnhancedQuoteCard(quote: quote)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Explore Wisdom")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadQuotes()
            }
        }
    }
    
    private func loadQuotes() {
        quotes = WisdomManager.shared.quotes.shuffled()
    }
}

// MARK: - Category Pill
struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
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

// MARK: - Background View
struct BackgroundView: View {
    @EnvironmentObject var backgroundManager: BackgroundImageManager
    
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)
                .ignoresSafeArea()
            
            if backgroundManager.showBackground,
               let image = backgroundManager.currentBackgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .ignoresSafeArea()
                    .opacity(0.1)
            }
        }
    }
}
