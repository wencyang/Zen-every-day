import SwiftUI

// Placeholder view wrapping existing SavedQuotesView
struct SavedView: View {
    var body: some View {
        NavigationView {
            SavedQuotesView()
        }
    }
}

// Simple profile view
struct ProfileView: View {
    @ObservedObject var streakManager: StreakManager
    @ObservedObject var prayerManager: PrayerManager
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Stats")) {
                    Text("Current streak: \(streakManager.currentStreak) days")
                }
                Section(header: Text("Prayers")) {
                    Text("Total prayers: \(prayerManager.prayers.count)")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

// Onboarding view shown to first time users
struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Zen Every Day")
                .font(.title)
                .fontWeight(.bold)
            Text("Discover daily wisdom, keep track of your reflections and build mindful habits.")
                .multilineTextAlignment(.center)
                .padding()
            Button("Get Started") {
                hasCompletedOnboarding = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// Simple error view used when loading fails
struct ErrorView: View {
    let message: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.red)
            Text(message)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// Calendar placeholder showing streak information
struct CalendarView: View {
    @ObservedObject var streakManager: StreakManager
    var body: some View {
        VStack(spacing: 16) {
            Text("Reading Streak")
                .font(.headline)
            Text("\(streakManager.currentStreak) days")
                .font(.largeTitle)
            Text("Calendar coming soon")
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// Basic journal view
struct JournalView: View {
    @State private var text: String = ""
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                TextEditor(text: $text)
                    .padding()
                    .frame(minHeight: 200)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2)))
                Spacer()
            }
            .padding()
            .navigationTitle("Journal")
        }
    }
}

// Simple breathing exercise view
struct BreathingExerciseView: View {
    @State private var isBreathing = false
    var body: some View {
        VStack(spacing: 20) {
            Text(isBreathing ? "Breathe Out" : "Breathe In")
                .font(.title)
            Button(isBreathing ? "Restart" : "Start") {
                isBreathing.toggle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// List of all reflections saved in UserDefaults
struct AllReflectionsView: View {
    @State private var reflections: [ReflectionEntry] = []
    var body: some View {
        List(reflections) { reflection in
            VStack(alignment: .leading, spacing: 4) {
                Text(reflection.reflection)
                if let mood = reflection.mood {
                    Text(mood).font(.caption).foregroundColor(.secondary)
                }
                Text(reflection.date, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onAppear(perform: loadReflections)
        .navigationTitle("Reflections")
    }

    private func loadReflections() {
        if let data = UserDefaults.standard.data(forKey: "reflectionHistory"),
           let decoded = try? JSONDecoder().decode([ReflectionEntry].self, from: data) {
            reflections = decoded.sorted { $0.date > $1.date }
        }
    }
}
