import Combine
import SwiftUI
import UIKit

struct SearchTopicItem {
  let text: String
  let emoji: String
  let color: Color
  let textColor: Color
}

// Helper view for search tips
struct SearchTipRow: View {
  let icon: String
  let tip: String
  let color: Color

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 16))
        .foregroundColor(color)
        .frame(width: 20)

      Text(tip)
        .font(.system(size: 14))
        .foregroundColor(.secondary)
        .multilineTextAlignment(.leading)

      Spacer()
    }
  }
}

struct SearchView: View {
  @State private var query: String = ""
  @State private var results: [WisdomQuote] = []
  @State private var errorMessage: String?
  @State private var searchWorkItem: DispatchWorkItem?
  @State private var isSearching = false
  @FocusState private var isTextFieldFocused: Bool

  // State for quote copying
  @State private var showCopyToast = false

  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedQuotesManager: SavedQuotesManager

  // Use singleton wisdom manager
  private var wisdomManager = WisdomManager.shared

  // Quick search suggestions - focused on specific words/phrases
  let quickSearches = [
    SearchTopicItem(text: "mindfulness", emoji: "🧘", color: .green.opacity(0.1), textColor: .green),
    SearchTopicItem(text: "compassion", emoji: "❤️", color: .pink.opacity(0.1), textColor: .pink),
    SearchTopicItem(text: "impermanence", emoji: "🍃", color: .orange.opacity(0.1), textColor: .orange),
    SearchTopicItem(text: "wisdom", emoji: "🕯", color: .purple.opacity(0.1), textColor: .purple),
    SearchTopicItem(text: "suffering", emoji: "😌", color: .blue.opacity(0.1), textColor: .blue),
  ]

  // Popular phrases that people often search for
  let popularPhrases = [
    "middle way", "right action", "impermanence",
  ]

  var body: some View {
    ZStack {
      // Background tap handler to dismiss keyboard
      Color.clear
        .contentShape(Rectangle())
        .onTapGesture {
          isTextFieldFocused = false
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)

      VStack(spacing: 0) {
        // Search Header
        VStack(spacing: 16) {
          // Search Bar
          HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(isTextFieldFocused ? .primary : .secondary)
              .font(.system(size: 20, weight: .medium))

            TextField("Search wisdom...", text: $query)
              .font(.system(size: 18, weight: .medium))
              .textFieldStyle(PlainTextFieldStyle())
              .disableAutocorrection(true)
              .autocapitalization(.none)
              .focused($isTextFieldFocused)
              .submitLabel(.search)
              .onSubmit {
                performSearch()
              }

            if !query.isEmpty {
              Button(action: {
                query = ""
                results = []
                isTextFieldFocused = false
              }) {
                Image(systemName: "xmark.circle.fill")
                  .foregroundColor(.secondary)
                  .font(.system(size: 18))
              }
            }

            if isSearching {
              ProgressView()
                .scaleEffect(0.8)
            }
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 16)
          .background(
            RoundedRectangle(cornerRadius: 16)
              .fill(Color(.systemBackground))
              .shadow(color: Color.primary.opacity(0.1), radius: 8, x: 0, y: 2)
              .overlay(
                RoundedRectangle(cornerRadius: 16)
                  .stroke(
                    Color.primary.opacity(isTextFieldFocused ? 0.3 : 0.1),
                    lineWidth: isTextFieldFocused ? 2 : 1
                  )
              )
          )
          .padding(.horizontal)
          .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)

          if query.isEmpty {
            // Welcome Section - More compact
            VStack(spacing: 8) {
              Image(systemName: "book.fill")
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .padding(8)
                .background(
                  Circle()
                    .fill(Color.blue.opacity(0.1))
                )

              VStack(spacing: 2) {
                Text("Search Teachings")
                  .font(.headline)
                  .fontWeight(.semibold)

                Text("Discover quotes that inspire your practice")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
            .padding(.vertical, 8)
          }
        }
        .background(
          LinearGradient(
            gradient: Gradient(colors: [
              Color.blue.opacity(0.05),
              Color.purple.opacity(0.05),
              Color.white,
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

        if let errorMessage = errorMessage {
          Text(errorMessage)
            .foregroundColor(.red)
            .font(.system(size: settings.fontSize))
            .padding(.horizontal)
        }

        // Loading state while wisdom loads
        if wisdomManager.isLoading {
          VStack(spacing: 16) {
            ProgressView()
              .scaleEffect(1.2)
            Text("Loading wisdom...")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .frame(maxHeight: .infinity)
        }
        // Content area
        else if query.isEmpty {
          ScrollView {
            LazyVStack(spacing: 32) {
              // Quick Search Section - Specific searchable terms
              VStack(alignment: .leading, spacing: 16) {
                HStack {
                  Image(systemName: "bolt.fill")
                    .foregroundColor(.yellow)
                  Text("Quick Search")
                    .font(.headline)
                    .fontWeight(.semibold)
                  Spacer()
                }
                .padding(.horizontal)

                LazyVGrid(
                  columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2),
                  spacing: 12
                ) {
                  ForEach(Array(quickSearches.enumerated()), id: \.offset) { index, item in
                    Button(action: {
                      query = item.text
                      isTextFieldFocused = false
                      performSearch()
                    }) {
                      HStack(spacing: 8) {
                        Text(item.emoji)
                          .font(.title3)
                        Text(item.text)
                          .font(.system(size: 14, weight: .medium))
                          .foregroundColor(item.textColor)
                          .lineLimit(1)
                      }
                      .frame(maxWidth: .infinity, minHeight: 44)
                      .padding(.horizontal, 12)
                      .background(
                        RoundedRectangle(cornerRadius: 10)
                          .fill(item.color)
                          .overlay(
                            RoundedRectangle(cornerRadius: 10)
                              .stroke(item.textColor.opacity(0.3), lineWidth: 1)
                          )
                      )
                    }
                    .buttonStyle(ScaleButtonStyle())
                  }
                }
                .padding(.horizontal)
              }

              // Popular Phrases - Compact horizontal scroll
              VStack(alignment: .leading, spacing: 16) {
                HStack {
                  Image(systemName: "quote.bubble.fill")
                    .foregroundColor(.purple)
                  Text("Popular Phrases")
                    .font(.headline)
                    .fontWeight(.semibold)
                  Spacer()
                }
                .padding(.horizontal)

                ScrollView(.horizontal, showsIndicators: false) {
                  HStack(spacing: 8) {
                    ForEach(popularPhrases, id: \.self) { phrase in
                      Button(action: {
                        query = phrase
                        isTextFieldFocused = false
                        performSearch()
                      }) {
                        Text("\"\(phrase)\"")
                          .font(.system(size: 13, weight: .medium))
                          .foregroundColor(.purple)
                          .padding(.horizontal, 12)
                          .padding(.vertical, 6)
                          .background(
                            Capsule()
                              .fill(Color.purple.opacity(0.1))
                              .overlay(
                                Capsule()
                                  .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                              )
                          )
                      }
                      .buttonStyle(ScaleButtonStyle())
                    }
                  }
                  .padding(.horizontal)
                }
              }

              // Search Tips Section
              VStack(alignment: .leading, spacing: 12) {
                HStack {
                  Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                  Text("Search Tips")
                    .font(.headline)
                    .fontWeight(.semibold)
                  Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                  SearchTipRow(
                    icon: "doc.text.magnifyingglass",
                    tip: "Search for specific words like \"mindfulness\" or \"compassion\"",
                    color: .blue
                  )

                  SearchTipRow(
                    icon: "quote.bubble",
                    tip: "Try phrases in quotes like \"middle way\" or \"right action\"",
                    color: .green
                  )

                  SearchTipRow(
                    icon: "person.fill",
                    tip: "Search for teachers like \"Buddha\", \"Dogen\", or \"Hakuin\"",
                    color: .purple
                  )

                  SearchTipRow(
                    icon: "location.fill",
                    tip: "Explore concepts like \"impermanence\" or \"suffering\"",
                    color: .red
                  )
                }
              }
              .padding(.horizontal)
              .padding(.vertical, 16)
              .background(
                RoundedRectangle(cornerRadius: 16)
                  .fill(Color(.systemGray6))
              )
              .padding(.horizontal)

              Spacer(minLength: 100)
            }
            .padding(.top, 24)
          }
          .onTapGesture {
            isTextFieldFocused = false
          }
        } else if results.isEmpty && !isSearching {
          VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 40))
              .foregroundColor(.secondary)
            Text("No quotes found for \"\(query)\"")
              .foregroundColor(.secondary)
              .font(.system(size: settings.fontSize))
              .multilineTextAlignment(.center)
            Text("Try different keywords or check your spelling")
              .foregroundColor(.secondary)
              .font(.system(size: settings.fontSize * 0.8))
              .multilineTextAlignment(.center)
          }
          .padding()
          .frame(maxHeight: .infinity)
          .onTapGesture {
            isTextFieldFocused = false
          }
        } else {
          VStack(spacing: 0) {
            HStack {
              Text("\(results.count) result\(results.count == 1 ? "" : "s") for \"\(query)\"")
                .font(.caption)
                .foregroundColor(.secondary)
              Spacer()

              if isSearching {
                ProgressView()
                  .scaleEffect(0.7)
              }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            List(results, id: \.id) { quote in
              HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                  // Highlighted quote text
                  HighlightedText(
                    text: quote.text,
                    searchQuery: query,
                    fontSize: settings.fontSize
                  )

                  if let author = quote.author {
                    Text(author)
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }
                }

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
                    if let author = quote.author {
                      copyText += "\n- \(author)"
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
              .padding(.vertical, 4)
              .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }
            .listStyle(PlainListStyle())
            .scrollDismissesKeyboard(.immediately)
          }
        }

        Spacer(minLength: 0)
      }
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .onChange(of: query) { oldValue, newValue in
      searchWorkItem?.cancel()

      if newValue.isEmpty {
        results = []
        isSearching = false
      } else if newValue.count >= 2 {  // Only search for 2+ characters
        isSearching = true
        let workItem = DispatchWorkItem {
          self.performSearch()
        }
        searchWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
      }
    }
    .toast(
      isShowing: $showCopyToast,
      message: "Quote Copied",
      icon: "doc.on.doc.fill",
      color: .green,
      duration: 1.2
    )
  }

  func performSearch() {
    guard wisdomManager.isLoaded, !query.isEmpty else {
      DispatchQueue.main.async {
        self.results = []
        self.isSearching = false
      }
      return
    }

    let searchQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    DispatchQueue.global(qos: .userInitiated).async {
      let searchResults = self.wisdomManager.quotes.filter { quote in
        quote.text.localizedCaseInsensitiveContains(searchQuery) ||
          (quote.author?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
          (quote.tags?.contains { $0.localizedCaseInsensitiveContains(searchQuery) } ?? false)
      }

      DispatchQueue.main.async {
        withAnimation(.easeInOut(duration: 0.2)) {
          self.results = Array(searchResults.prefix(100))
          self.isSearching = false
        }
      }
    }
  }
}

// Custom view for highlighting search terms in text - Optimized
struct HighlightedText: View {
  let text: String
  let searchQuery: String
  let fontSize: Double

  var body: some View {
    if searchQuery.isEmpty {
      Text(text)
        .font(.system(size: fontSize))
    } else {
      let attributedString = createHighlightedAttributedString()
      Text(AttributedString(attributedString))
        .font(.system(size: fontSize))
    }
  }

  private func createHighlightedAttributedString() -> NSAttributedString {
    let attributedString = NSMutableAttributedString(string: text)
    let range = NSRange(location: 0, length: text.count)

    // Set base attributes
    attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: range)
    attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: fontSize), range: range)

    // Find and highlight search terms - Optimized for performance
    let searchTerms = searchQuery.lowercased()
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty && $0.count > 1 }  // Only highlight meaningful terms
      .prefix(3)  // Limit to first 3 terms for performance

    for searchTerm in searchTerms {
      let searchRange = text.lowercased()
      var searchStartIndex = searchRange.startIndex

      // Limit highlighting iterations for performance
      var iterationCount = 0
      let maxIterations = 10

      while let range = searchRange.range(
        of: searchTerm, range: searchStartIndex..<searchRange.endIndex),
        iterationCount < maxIterations
      {
        let nsRange = NSRange(range, in: text)

        // Apply highlight styling
        attributedString.addAttribute(
          .backgroundColor, value: UIColor.systemYellow.withAlphaComponent(0.4), range: nsRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.label, range: nsRange)
        attributedString.addAttribute(
          .font, value: UIFont.boldSystemFont(ofSize: fontSize), range: nsRange)

        searchStartIndex = range.upperBound
        iterationCount += 1
      }
    }

    return attributedString
  }
}

struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

struct SearchView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      SearchView()
        .environmentObject(UserSettings())
    }
  }
}
