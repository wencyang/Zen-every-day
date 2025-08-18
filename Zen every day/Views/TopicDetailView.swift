import SwiftUI
import UIKit

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
  @State private var topicQuotes: [WisdomQuote] = []
  @State private var isLoading = true
  @State private var showCopyToast = false
  @State private var errorMessage: String?

  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedQuotesManager: SavedQuotesManager

  // Reference to wisdom manager
  private let wisdomManager = WisdomManager.shared

  var body: some View {
    Group {
      if isLoading {
        VStack(spacing: 20) {
          ProgressView()
            .scaleEffect(1.2)

          Text("Finding quotes about \(topic.name.lowercased())...")
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
      } else if topicQuotes.isEmpty {
        VStack(spacing: 16) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 50))
            .foregroundColor(.secondary)

          Text("No quotes found")
            .font(.headline)

          Text("No quotes found for \(topic.name). Try exploring other topics.")
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
              Text("\(topicQuotes.count) quotes about")
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

            // Quotes list
            LazyVStack(spacing: 16) {
              ForEach(Array(topicQuotes.enumerated()), id: \.element.id) { _, quote in
                VStack(alignment: .leading, spacing: 12) {
                  // Quote text with highlighted keywords
                  HighlightedQuoteText(
                    text: quote.text,
                    keyword: topic.keyword,
                    fontSize: settings.fontSize
                  )

                  if let author = quote.author?.removingParaphrase {
                    Text(author)
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                  if let work = quote.work?.removingParaphrase, !work.isEmpty {
                    Text(work)
                      .font(.caption2)
                      .foregroundColor(.secondary)
                  }

                  HStack {
                    Spacer()
                    HStack(spacing: 8) {
                      Button(action: {
                        savedQuotesManager.toggleQuoteSaved(quote)
                      }) {
                        Image(systemName: savedQuotesManager.isQuoteSaved(quote) ? "bookmark.fill" : "bookmark")
                          .font(.system(size: 16))
                          .foregroundColor(savedQuotesManager.isQuoteSaved(quote) ? .blue : .secondary)
                      }
                      .buttonStyle(PlainButtonStyle())

                      Button(action: {
                        var copyText = quote.text
                        if let author = quote.author?.removingParaphrase {
                          copyText += "\n- \(author)"
                        }
                        if let work = quote.work?.removingParaphrase, !work.isEmpty {
                          copyText += ", \(work)"
                        }
                        UIPasteboard.general.string = copyText
                        showCopyToast = true
                      }) {
                        Image(systemName: "doc.on.doc")
                          .font(.system(size: 16))
                          .foregroundColor(.blue)
                      }
                      .buttonStyle(PlainButtonStyle())
                    }
                  }
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
      message: "Quote Copied",
      icon: "doc.on.doc.fill",
      color: .green,
      duration: 1.2
    )
    .onAppear {
      loadTopicQuotes()
    }
    // Removed onChange to prevent unnecessary reloads - we'll handle loading state internally
  }
  private func loadTopicQuotes() {
    isLoading = true
    errorMessage = nil

    guard wisdomManager.isLoaded else {
      errorMessage = "Wisdom not available"
      isLoading = false
      return
    }

    DispatchQueue.global(qos: .userInitiated).async {
      let filtered = wisdomManager.quotes.filter { quote in
        if let tags = quote.tags,
          tags.contains(where: {
            $0.caseInsensitiveCompare(self.topic.keyword) == .orderedSame
          }) {
          return true
        }
        return quote.text.localizedCaseInsensitiveContains(self.topic.keyword)
      }

      let searchResults = Array(filtered.prefix(100))

      DispatchQueue.main.async {
        self.topicQuotes = searchResults
        self.isLoading = false

        #if DEBUG
          print("✅ TopicDetailView: Found \(searchResults.count) quotes for '\(self.topic.keyword)'")
        #endif
      }
    }
  }
}

// Custom view for highlighting keywords in quote text
struct HighlightedQuoteText: View {
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
    NavigationStack {
      TopicDetailView(topic: Topic(name: "Faith", keyword: "faith"))
        .environmentObject(UserSettings())
    }
  }
}
