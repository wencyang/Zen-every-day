import SwiftUI

struct QuoteOfTheDayView: View {
  @State private var history: [DailyQuoteEntry] = []
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedQuotesManager: SavedQuotesManager

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        VStack(spacing: 12) {
          Text("Quote of the Day")
            .font(.title2)
            .fontWeight(.bold)

          if !history.isEmpty {
            Text("\(history.count) day\(history.count == 1 ? "" : "s") of inspiration")
              .font(.subheadline)
              .foregroundColor(.secondary)
          } else {
            Text("Your daily quote history")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        .padding(.top, 20)

        if history.isEmpty {
          VStack(spacing: 20) {
            Image(systemName: "quote.bubble")
              .font(.system(size: 60))
              .foregroundColor(.secondary.opacity(0.5))

            Text("No daily quotes yet")
              .font(.title3)
              .fontWeight(.medium)
              .foregroundColor(.secondary)

            Text("Your daily quote history will appear here as you use the app")
              .font(.subheadline)
              .foregroundColor(.secondary.opacity(0.8))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
          }
          .padding(.vertical, 40)
        } else {
          LazyVStack(spacing: 16) {
            ForEach(history.sorted(by: { $0.date > $1.date })) { entry in
              QuoteHistoryCard(entry: entry, onBookmark: { quote in
                savedQuotesManager.toggleQuoteSaved(quote)
              })
              .environmentObject(settings)
              .environmentObject(savedQuotesManager)
            }
          }
          .padding(.horizontal)
        }

        VStack(spacing: 8) {
          Text("Daily quotes are automatically saved for 30 days")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)

          Text("Each quote is carefully selected to inspire your day")
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
    .onAppear(perform: loadHistory)
  }

  private func loadHistory() {
    if let data = UserDefaults.standard.data(forKey: "dailyQuoteHistory"),
       let loaded = try? JSONDecoder().decode([DailyQuoteEntry].self, from: data) {
      history = loaded
    }
  }
}

struct QuoteHistoryCard: View {
  let entry: DailyQuoteEntry
  let onBookmark: (WisdomQuote) -> Void
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedQuotesManager: SavedQuotesManager
  @State private var isExpanded = false

  private var quote: WisdomQuote {
    WisdomQuote(
      id: entry.id,
      author: entry.author,
      text: entry.text,
      work: nil,
      ref: nil,
      language: nil,
      license: nil,
      source: nil,
      tags: nil
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(formattedDate(entry.date))
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)
          if let author = entry.author {
            Text(author)
              .font(.system(size: 13))
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        HStack(spacing: 16) {
          Button(action: { onBookmark(quote) }) {
            Image(systemName: savedQuotesManager.isQuoteSaved(quote) ? "bookmark.fill" : "bookmark")
              .font(.system(size: 18))
              .foregroundColor(savedQuotesManager.isQuoteSaved(quote) ? .blue : .secondary)
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

struct QuoteOfTheDayView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      QuoteOfTheDayView()
        .environmentObject(UserSettings())
        .environmentObject(SavedQuotesManager())
    }
  }
}
