import SwiftUI

// Topic model for the detail view (keeping original structure for compatibility)
struct Topic: Identifiable, Hashable {
  let id = UUID()
  let name: String
  let keyword: String

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: Topic, rhs: Topic) -> Bool {
    lhs.id == rhs.id
  }
}

struct TopicDetailView: View {
  let topic: Topic
  @State private var topicVerses: [Verse] = []
  @State private var isLoading = true
  @State private var selectedVerseForCard: Verse?
  @State private var showCopyToast = false
  @State private var errorMessage: String?

  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedVersesManager: SavedVersesManager

  // Use direct reference to singleton instead of @StateObject to prevent unnecessary view updates
  private let bibleManager = BibleManager.shared

  var body: some View {
    Group {
      if isLoading {
        VStack(spacing: 20) {
          ProgressView()
            .scaleEffect(1.2)

          Text("Finding verses about \(topic.name.lowercased())...")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if let errorMessage = errorMessage {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 50))
            .foregroundColor(.orange)

          Text("Error Loading Content")
            .font(.headline)

          Text(errorMessage)
            .font(.system(size: settings.fontSize))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if topicVerses.isEmpty {
        VStack(spacing: 16) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 50))
            .foregroundColor(.secondary)

          Text("No verses found")
            .font(.headline)

          Text("No verses found for \(topic.name). Try exploring other topics.")
            .font(.system(size: settings.fontSize))
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          VStack(spacing: 0) {
            // Header with topic info
            VStack(spacing: 12) {
              Text("\(topicVerses.count) verses about")
                .font(.subheadline)
                .foregroundColor(.secondary)

              Text(topic.name)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
              LinearGradient(
                gradient: Gradient(colors: [
                  Color.blue.opacity(0.05),
                  Color.clear,
                ]),
                startPoint: .top,
                endPoint: .bottom
              )
            )

            // Verses list
            LazyVStack(spacing: 16) {
              ForEach(Array(topicVerses.enumerated()), id: \.element.id) { index, verse in
                VStack(alignment: .leading, spacing: 12) {
                  // Verse reference
                  HStack {
                    Text("\(verse.book_name) \(verse.chapter):\(verse.verse)")
                      .font(.system(size: 14, weight: .semibold))
                      .foregroundColor(.blue)

                    Spacer()

                    HStack(spacing: 12) {
                      // Share button
                      Button(action: {
                        selectedVerseForCard = verse
                      }) {
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

                      Button(action: {
                        savedVersesManager.toggleVerseSaved(verse)
                      }) {
                        Image(
                          systemName: savedVersesManager.isVerseSaved(verse)
                            ? "bookmark.fill" : "bookmark"
                        )
                        .font(.system(size: 16))
                        .foregroundColor(
                          savedVersesManager.isVerseSaved(verse) ? .blue : .secondary)
                      }
                      .buttonStyle(PlainButtonStyle())
                    }
                  }

                  // Verse text with highlighted keywords
                  HighlightedVerseText(
                    text: verse.text.cleanVerse,
                    keyword: topic.keyword,
                    fontSize: settings.fontSize
                  )
                }
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
                )
              }
              .padding(.horizontal)
            }
            .padding(.vertical)
          }
        }
        .background(Color(.systemGroupedBackground))
      }
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
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
    .onAppear {
      loadTopicVerses()
    }
    // Removed onChange to prevent unnecessary reloads - we'll handle loading state internally
  }

  private func loadTopicVerses() {
    // Always start with loading state
    isLoading = true
    errorMessage = nil

    // Check if Bible is ready immediately
    if bibleManager.isLoaded {
      performSearch()
    } else {
      // Bible not loaded yet, wait for it with polling instead of onChange
      waitForBibleAndSearch()
    }
  }

  private func waitForBibleAndSearch() {
    // Check if there's an error first
    if let error = bibleManager.errorMessage {
      errorMessage = error
      isLoading = false
      return
    }

    // If still loading, check again after a short delay
    if bibleManager.isLoading {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.waitForBibleAndSearch()
      }
      return
    }

    // Bible should be loaded now
    if bibleManager.isLoaded {
      performSearch()
    } else {
      // Something went wrong
      errorMessage = "Failed to load Bible"
      isLoading = false
    }
  }

  private func performSearch() {
    // Perform search on background thread
    DispatchQueue.global(qos: .userInitiated).async {
      // Get the Bible directly for more reliable search
      guard let bible = self.bibleManager.getBible() else {
        DispatchQueue.main.async {
          self.errorMessage = "Bible not available"
          self.isLoading = false
        }
        return
      }

      // Perform direct search on Bible verses
      let filtered = bible.verses.filter { verse in
        verse.text.cleanVerse.localizedCaseInsensitiveContains(self.topic.keyword)
      }

      // Take up to 100 verses
      let searchResults = Array(filtered.prefix(100))

      DispatchQueue.main.async {
        self.topicVerses = searchResults
        self.isLoading = false

        #if DEBUG
          print(
            "✅ TopicDetailView: Found \(searchResults.count) verses for '\(self.topic.keyword)'")
        #endif
      }
    }
  }
}

// Custom view for highlighting keywords in verse text
struct HighlightedVerseText: View {
  let text: String
  let keyword: String
  let fontSize: Double
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    let attributedString = createHighlightedAttributedString()
    Text(AttributedString(attributedString))
      .font(.system(size: fontSize))
      .fixedSize(horizontal: false, vertical: true)
  }

  private func createHighlightedAttributedString() -> NSAttributedString {
    let attributedString = NSMutableAttributedString(string: text)
    let range = NSRange(location: 0, length: text.count)

    // Set base attributes
    attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: range)
    attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize), range: range)

    // Find and highlight the keyword
    let searchRange = text.lowercased()
    let searchTerm = keyword.lowercased()
    var searchStartIndex = searchRange.startIndex

    while let range = searchRange.range(
      of: searchTerm, range: searchStartIndex..<searchRange.endIndex)
    {
      let nsRange = NSRange(range, in: text)

      // Apply highlight styling with better dark mode support
      let highlightColor =
        colorScheme == .dark
        ? UIColor.systemBlue.withAlphaComponent(0.3)
        : UIColor.systemBlue.withAlphaComponent(0.2)

      attributedString.addAttribute(
        .backgroundColor, value: highlightColor, range: nsRange)
      attributedString.addAttribute(.foregroundColor, value: UIColor.systemBlue, range: nsRange)
      attributedString.addAttribute(
        .font, value: UIFont.boldSystemFont(ofSize: fontSize), range: nsRange)

      searchStartIndex = range.upperBound
    }

    return attributedString
  }
}

struct TopicDetailView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      TopicDetailView(topic: Topic(name: "Faith", keyword: "faith"))
        .environmentObject(UserSettings())
        .environmentObject(SavedVersesManager())
    }
  }
}
