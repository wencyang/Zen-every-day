import SwiftUI
import UIKit

// MARK: - Enhanced Quote Card View
struct EnhancedQuoteCard: View {
    let quote: WisdomQuote
    @State private var isExpanded = false
    @State private var showingShareSheet = false
    @State private var showingReflection = false
    @State private var isPressed = false
    @State private var copiedToClipboard = false
    @State private var savedAnimation = false
    
    @EnvironmentObject var savedQuotesManager: SavedQuotesManager
    @EnvironmentObject var userSettings: UserSettings
    @EnvironmentObject var streakManager: StreakManager
    
    // Animation states
    @State private var heartScale: CGFloat = 1.0
    @State private var bookmarkRotation: Double = 0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Quote content
            VStack(alignment: .leading, spacing: 12) {
                // Quote text
                Text(quote.text.cleanQuote.removingParaphrase)
                    .font(.system(size: CGFloat(userSettings.fontSize), weight: .regular, design: .serif))
                    .lineLimit(isExpanded ? nil : 4)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.primary)
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
                
                // Show more/less button for long quotes
                if quote.text.count > 200 {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isExpanded.toggle()
                        }
                        hapticFeedback(.light)
                    }) {
                        HStack(spacing: 4) {
                            Text(isExpanded ? "Show less" : "Read more")
                                .font(.caption)
                                .fontWeight(.medium)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
                
                // Author and source
                VStack(alignment: .leading, spacing: 6) {
                    if let author = quote.author {
                        HStack(spacing: 6) {
                            Image(systemName: "person.circle.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(author)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if let work = quote.work, isExpanded {
                        HStack(spacing: 6) {
                            Image(systemName: "book.closed.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(work)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    
                    if let ref = quote.ref, isExpanded {
                        HStack(spacing: 6) {
                            Image(systemName: "bookmark.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(ref)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
            
            // Tags (if available and expanded)
            if let tags = quote.tags, !tags.isEmpty, isExpanded {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(tag: tag)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            
            Divider()
                .opacity(0.3)
            
            // Action buttons
            HStack(spacing: 0) {
                // Save/Bookmark button
                ActionButton(
                    icon: savedQuotesManager.isQuoteSaved(quote) ? "bookmark.fill" : "bookmark",
                    color: savedQuotesManager.isQuoteSaved(quote) ? .yellow : .secondary,
                    scale: bookmarkRotation,
                    action: {
                        toggleSave()
                    }
                )
                
                Spacer()
                
                // Reflect button
                ActionButton(
                    icon: "pencil.and.ellipsis.rectangle",
                    color: .purple,
                    action: {
                        showingReflection = true
                        hapticFeedback(.light)
                    }
                )
                
                Spacer()
                
                // Copy button
                ActionButton(
                    icon: copiedToClipboard ? "checkmark.circle.fill" : "doc.on.doc",
                    color: copiedToClipboard ? .green : .secondary,
                    action: {
                        copyToClipboard()
                    }
                )
                
                Spacer()
                
                // Share button
                ActionButton(
                    icon: "square.and.arrow.up",
                    color: .blue,
                    action: {
                        showingShareSheet = true
                        hapticFeedback(.light)
                    }
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.regular)
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [formatQuoteForSharing()])
        }
        .sheet(isPresented: $showingReflection) {
            QuoteReflectionView(quote: quote)
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            // Track quote read
            streakManager.incrementQuotesRead()
        }
    }
    
    // MARK: - Helper Functions
    
    private func toggleSave() {
        if savedQuotesManager.isQuoteSaved(quote) {
            savedQuotesManager.removeQuote(quote)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bookmarkRotation = 0
            }
        } else {
            savedQuotesManager.saveQuote(quote)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bookmarkRotation = 360
            }
        }
        hapticFeedback(.medium)
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = formatQuoteForSharing()
        
        withAnimation(.easeInOut(duration: 0.3)) {
            copiedToClipboard = true
        }
        
        hapticFeedback(.light)
        
        // Reset after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.easeInOut(duration: 0.3)) {
                copiedToClipboard = false
            }
        }
    }
    
    private func formatQuoteForSharing() -> String {
        var text = "\"\(quote.text.cleanQuote.removingParaphrase)\""
        if let author = quote.author {
            text += "\n\n— \(author)"
        }
        if let work = quote.work {
            text += "\n\(work)"
        }
        text += "\n\nShared from Zen Every Day"
        return text
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let icon: String
    let color: Color
    var scale: CGFloat = 0
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .rotationEffect(.degrees(scale))
                .scaleEffect(isPressed ? 0.8 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - Tag Chip Component
struct TagChip: View {
    let tag: String
    
    var body: some View {
        Text("#\(tag)")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.blue.opacity(0.1))
            )
            .foregroundColor(.blue)
    }
}

// MARK: - Quote Reflection View
struct QuoteReflectionView: View {
    let quote: WisdomQuote
    @State private var reflection = ""
    @State private var selectedMood: Mood?
    @State private var gratitudes: [String] = ["", "", ""]
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var streakManager: StreakManager
    
    enum Mood: String, CaseIterable {
        case peaceful = "😌"
        case happy = "😊"
        case thoughtful = "🤔"
        case grateful = "🙏"
        case motivated = "💪"
        case anxious = "😰"
        
        var name: String {
            switch self {
            case .peaceful: return "Peaceful"
            case .happy: return "Happy"
            case .thoughtful: return "Thoughtful"
            case .grateful: return "Grateful"
            case .motivated: return "Motivated"
            case .anxious: return "Anxious"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Quote reference (compact)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reflecting on:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(quote.text.cleanQuote.removingParaphrase)
                            .font(.system(.subheadline, design: .serif))
                            .lineLimit(3)
                            .foregroundColor(.secondary)
                        
                        if let author = quote.author {
                            Text("— \(author)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                    
                    // Mood selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How does this make you feel?")
                            .font(.headline)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 12) {
                            ForEach(Mood.allCases, id: \.self) { mood in
                                MoodButton(
                                    mood: mood,
                                    isSelected: selectedMood == mood,
                                    action: {
                                        selectedMood = mood
                                        hapticFeedback(.light)
                                    }
                                )
                            }
                        }
                    }
                    
                    // Reflection input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your thoughts")
                            .font(.headline)
                        
                        Text("How does this wisdom apply to your life today?")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $reflection)
                            .frame(minHeight: 120)
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.1))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                    }
                    
                    // Gratitude section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Three things I'm grateful for")
                            .font(.headline)
                        
                        ForEach(0..<3) { index in
                            HStack(spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.system(.body, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                TextField("I'm grateful for...", text: $gratitudes[index])
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveReflection()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(reflection.isEmpty && gratitudes.allSatisfy { $0.isEmpty })
                }
            }
        }
    }
    
    private func saveReflection() {
        let entry = ReflectionEntry(
            quoteId: quote.id,
            quoteText: quote.text,
            reflection: reflection,
            mood: selectedMood?.name,
            gratitudes: gratitudes.filter { !$0.isEmpty },
            date: Date()
        )
        
        // Save to UserDefaults or Core Data
        var entries = getReflectionHistory()
        entries.append(entry)
        saveReflectionHistory(entries)
        
        // Update achievement progress
        let totalEntries = entries.count
        UserDefaults.standard.set(totalEntries, forKey: "totalJournalEntries")
        
        hapticFeedback(.success)
    }
    
    private func getReflectionHistory() -> [ReflectionEntry] {
        if let data = UserDefaults.standard.data(forKey: "reflectionHistory"),
           let entries = try? JSONDecoder().decode([ReflectionEntry].self, from: data) {
            return entries
        }
        return []
    }
    
    private func saveReflectionHistory(_ entries: [ReflectionEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: "reflectionHistory")
        }
    }
    
    private func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    private func hapticFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - Mood Button Component
struct MoodButton: View {
    let mood: QuoteReflectionView.Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(mood.rawValue)
                    .font(.title2)
                
                Text(mood.name)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Reflection Entry Model
struct ReflectionEntry: Codable, Identifiable {
    let id: UUID = UUID()
    let quoteId: String
    let quoteText: String
    let reflection: String
    let mood: String?
    let gratitudes: [String]
    let date: Date
}

// MARK: - Floating Quote View (for Daily Wisdom)
struct FloatingQuoteView: View {
    let quote: WisdomQuote
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            // Decorative element
            Image(systemName: "quote.opening")
                .font(.largeTitle)
                .foregroundColor(.secondary.opacity(0.3))
            
            // Quote text
            Text(quote.text.cleanQuote.removingParaphrase)
                .font(.system(.title3, design: .serif))
                .multilineTextAlignment(.center)
                .lineLimit(8)
                .minimumScaleFactor(0.8)
            
            // Author
            if let author = quote.author {
                HStack {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 30, height: 1)
                    
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Rectangle()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 30, height: 1)
                }
            }
            
            Image(systemName: "quote.closing")
                .font(.largeTitle)
                .foregroundColor(.secondary.opacity(0.3))
        }
        .padding(30)
        .background(
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.05),
                        Color.purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                
                // Floating animation background
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.blue.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .offset(x: -50, y: -50)
                    .blur(radius: 20)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.purple.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .offset(x: 50, y: 50)
                    .blur(radius: 20)
            }
            .clipShape(RoundedRectangle(cornerRadius: 24))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.3),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        .offset(y: offset)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                offset = 0
                opacity = 1
            }
            
            // Gentle floating animation
            withAnimation(
                .easeInOut(duration: 3)
                .repeatForever(autoreverses: true)
            ) {
                offset = -10
            }
        }
    }
}