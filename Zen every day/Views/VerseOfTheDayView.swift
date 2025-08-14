import SwiftUI

struct VerseOfTheDayView: View {
  @State private var history: [DailyVerseEntry] = []
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedVersesManager: SavedVersesManager

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header Section
        VStack(spacing: 16) {
          // Icon and Title
          VStack(spacing: 12) {
            VStack(spacing: 4) {
              Text("Verse of the Day")
                .font(.title2)
                .fontWeight(.bold)

              if !history.isEmpty {
                Text("\(history.count) day\(history.count == 1 ? "" : "s") of spiritual journey")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              } else {
                Text("Your daily verse history")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
            }
          }
        }
        .padding(.top, 20)

        // Content
        if history.isEmpty {
          // Empty State
          VStack(spacing: 20) {
            Image(systemName: "book.closed")
              .font(.system(size: 60))
              .foregroundColor(.secondary.opacity(0.5))

            Text("No daily verses yet")
              .font(.title3)
              .fontWeight(.medium)
              .foregroundColor(.secondary)

            Text("Your daily verse history will appear here as you use the app")
              .font(.subheadline)
              .foregroundColor(.secondary.opacity(0.8))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
          }
          .padding(.vertical, 40)
        } else {
          // History List
          LazyVStack(spacing: 16) {
            ForEach(history.sorted(by: { $0.date > $1.date })) { entry in
              VerseHistoryCard(
                entry: entry,
                onBookmark: { verse in
                  savedVersesManager.toggleVerseSaved(verse)
                }
              )
              .environmentObject(settings)
              .environmentObject(savedVersesManager)
            }
          }
          .padding(.horizontal)
        }

        // Footer
        VStack(spacing: 8) {
          Text("Daily verses are automatically saved for 30 days")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

          Text("Each verse is carefully selected to inspire and guide your day")
            .font(.caption2)
            .foregroundColor(.secondary.opacity(0.7))
            .multilineTextAlignment(.center)
        }
        .padding(.bottom, 40)
      }
    }
    .background(
      LinearGradient(
        gradient: Gradient(colors: [
          Color(.systemGroupedBackground),
          Color(.systemBackground),
        ]),
        startPoint: .top,
        endPoint: .bottom
      )
    )
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      loadHistory()
    }
  }

  func loadHistory() {
    if let data = UserDefaults.standard.data(forKey: "dailyVerseHistory"),
      let loadedHistory = try? JSONDecoder().decode([DailyVerseEntry].self, from: data)
    {
      history = loadedHistory
    }
  }
}

struct VerseHistoryCard: View {
  let entry: DailyVerseEntry
  let onBookmark: (Verse) -> Void
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedVersesManager: SavedVersesManager
  @State private var isExpanded = false

  var verse: Verse {
    // Create a Verse object from the entry for bookmark functionality
    let components = entry.reference.components(separatedBy: " ")
    let bookName = components.dropLast().joined(separator: " ")
    let chapterVerse = components.last ?? ""
    let parts = chapterVerse.components(separatedBy: ":")

    return Verse(
      book_name: bookName,
      book: 1,  // Default value
      chapter: Int(parts.first ?? "1") ?? 1,
      verse: Int(parts.last ?? "1") ?? 1,
      text: entry.text
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header with date and actions
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 4) {
          Text(formattedDate(entry.date))
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.blue)

          Text(entry.reference)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
        }

        Spacer()

        HStack(spacing: 16) {
          Button(action: {
            onBookmark(verse)
          }) {
            Image(systemName: savedVersesManager.isVerseSaved(verse) ? "bookmark.fill" : "bookmark")
              .font(.system(size: 18))
              .foregroundColor(savedVersesManager.isVerseSaved(verse) ? .blue : .secondary)
          }
          .buttonStyle(PlainButtonStyle())

          Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              isExpanded.toggle()
            }
          }) {
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
              .font(.system(size: 20))
              .foregroundColor(.blue)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)

      // Verse text (expandable)
      VStack(alignment: .leading, spacing: 12) {
        if isExpanded {
          Divider()
            .padding(.horizontal, 16)

          Text(entry.text)
            .font(.system(size: settings.fontSize))
            .foregroundColor(.primary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .transition(
              .asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
              )
            )
        } else {
          // Preview text
          Text(entry.text)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .lineLimit(2)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
      }
    }
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.secondarySystemGroupedBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(
          LinearGradient(
            gradient: Gradient(colors: [
              Color.blue.opacity(0.2),
              Color.purple.opacity(0.1),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        isExpanded.toggle()
      }
    }
  }

  private func formattedDate(_ dateString: String) -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    guard let date = formatter.date(from: dateString) else {
      return dateString
    }

    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
      return "Today"
    } else if calendar.isDateInYesterday(date) {
      return "Yesterday"
    } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
      let dayFormatter = DateFormatter()
      dayFormatter.dateFormat = "EEEE"
      return dayFormatter.string(from: date)
    } else {
      let displayFormatter = DateFormatter()
      displayFormatter.dateStyle = .medium
      return displayFormatter.string(from: date)
    }
  }
}

struct VerseOfTheDayView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      VerseOfTheDayView()
        .environmentObject(UserSettings())
        .environmentObject(SavedVersesManager())
    }
  }
}
