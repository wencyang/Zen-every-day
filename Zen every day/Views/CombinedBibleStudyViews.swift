import SwiftUI

struct CombinedBibleStudyView: View {
  @EnvironmentObject var settings: UserSettings
  @State private var selectedTab = 0  // 0: Topics, 1: Books
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    VStack(spacing: 0) {
      // Header
      VStack(spacing: 16) {
        VStack(spacing: 8) {
          HStack {
            Image(systemName: "book.fill")
              .font(.system(size: 24))
              .foregroundColor(.blue)

            Text("Bible Study")
              .font(.title2)
              .fontWeight(.bold)
          }

          Text("Explore Scripture by theme or browse by book")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        // Tab Selector
        HStack(spacing: 0) {
          BibleStudyTabButton(
            title: "Topics",
            icon: "square.grid.2x2",
            isSelected: selectedTab == 0,
            action: { selectedTab = 0 }
          )

          BibleStudyTabButton(
            title: "Books",
            icon: "books.vertical",
            isSelected: selectedTab == 1,
            action: { selectedTab = 1 }
          )
        }
        .padding(3)
        .background(colorScheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .padding()
      .background(Color(.systemGroupedBackground))

      // Content
      TabView(selection: $selectedTab) {
        TopicalStudyView()
          .tag(0)

        TraditionalBibleView()
          .tag(1)
      }
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
      .id(colorScheme)
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Bible Study Tab Button Component
struct BibleStudyTabButton: View {
  let title: String
  let icon: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: icon)
          .font(.system(size: 14, weight: .medium))
        Text(title)
          .font(.system(size: 14, weight: .medium))
      }
      .foregroundColor(isSelected ? .white : .primary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 6)
          .fill(isSelected ? Color.blue : Color.clear)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Topical Study View (Enhanced Topics)
struct TopicalStudyView: View {
  @EnvironmentObject var settings: UserSettings
  @State private var path = NavigationPath()

  // Enhanced topic categories
  let topicCategories: [TopicCategory] = [
    TopicCategory(
      name: "Faith & Trust",
      icon: "hands.sparkles.fill",
      color: .blue,
      topics: [
        TopicItem(
          name: "Faith", keyword: "faith", icon: "hands.sparkles.fill", color: .blue,
          gradient: [.blue, .cyan], description: "Trust and belief in God's promises"),
        TopicItem(
          name: "Trust", keyword: "trust", icon: "heart.fill", color: .indigo,
          gradient: [.indigo, .blue], description: "Confidence in God's faithfulness"),
        TopicItem(
          name: "Guidance", keyword: "guidance", icon: "map.fill", color: .green,
          gradient: [.green, .mint], description: "Seeking God's direction"),
        TopicItem(
          name: "Obedience", keyword: "obedience", icon: "figure.walk", color: .orange,
          gradient: [.orange, .yellow], description: "Following God's commands"),
        TopicItem(
          name: "Perseverance", keyword: "perseverance", icon: "bolt.fill", color: .purple,
          gradient: [.purple, .indigo], description: "Enduring in faith"),
        TopicItem(
          name: "Patience", keyword: "patience", icon: "hourglass", color: .orange,
          gradient: [.orange, .yellow], description: "Waiting on God's timing"),
        TopicItem(
          name: "Courage", keyword: "courage", icon: "shield.fill", color: .indigo,
          gradient: [.indigo, .purple], description: "Strength to do what is right"),
        TopicItem(
          name: "Dependence", keyword: "dependence", icon: "hand.raised.fill", color: .teal,
          gradient: [.teal, .cyan], description: "Relying fully on God"),
      ]
    ),
    TopicCategory(
      name: "Love & Grace",
      icon: "heart.fill",
      color: .red,
      topics: [
        TopicItem(
          name: "Love", keyword: "love", icon: "heart.fill", color: .red, gradient: [.red, .pink],
          description: "God's love and love for others"),
        TopicItem(
          name: "Grace", keyword: "grace", icon: "sparkles", color: .purple,
          gradient: [.purple, .indigo], description: "Unmerited favor and divine blessing"),
        TopicItem(
          name: "Forgiveness", keyword: "forgive", icon: "hand.raised.fill", color: .teal,
          gradient: [.teal, .cyan], description: "Mercy and pardoning of sins"),
        TopicItem(
          name: "Kindness", keyword: "kindness", icon: "hand.thumbsup.fill", color: .teal,
          gradient: [.teal, .cyan], description: "Showing God's love to others"),
        TopicItem(
          name: "Mercy", keyword: "mercy", icon: "heart.circle.fill", color: .purple,
          gradient: [.purple, .pink], description: "God's compassion and forgiveness"),
        TopicItem(
          name: "Compassion", keyword: "compassion", icon: "hands.sparkles.fill", color: .pink,
          gradient: [.pink, .red], description: "Caring for others with Christ's love"),
        TopicItem(
          name: "Charity", keyword: "charity", icon: "gift.fill", color: .yellow,
          gradient: [.yellow, .orange], description: "Selfless giving to others"),
        TopicItem(
          name: "Unity", keyword: "unity", icon: "person.3.fill", color: .blue,
          gradient: [.blue, .green], description: "Harmony within the body of Christ"),
      ]
    ),
    TopicCategory(
      name: "Salvation & Redemption",
      icon: "cross.fill",
      color: .green,
      topics: [
        TopicItem(
          name: "Salvation", keyword: "salvation", icon: "cross.fill", color: .green,
          gradient: [.green, .mint], description: "Deliverance and eternal life through Christ"),
        TopicItem(
          name: "Redemption", keyword: "redemption", icon: "arrow.up.circle.fill", color: .indigo,
          gradient: [.indigo, .blue], description: "Restoration and being made new"),
        TopicItem(
          name: "Eternal Life", keyword: "eternal", icon: "infinity", color: .purple,
          gradient: [.purple, .pink], description: "Life everlasting with God"),
        TopicItem(
          name: "Deliverance", keyword: "deliverance", icon: "figure.walk", color: .teal,
          gradient: [.teal, .blue], description: "Freedom from bondage"),
        TopicItem(
          name: "Renewal", keyword: "renewal", icon: "arrow.clockwise", color: .mint,
          gradient: [.mint, .green], description: "Being made new in Christ"),
        TopicItem(
          name: "Baptism", keyword: "baptism", icon: "drop.fill", color: .blue,
          gradient: [.blue, .cyan], description: "Symbol of cleansing and faith"),
        TopicItem(
          name: "Resurrection", keyword: "resurrection", icon: "arrow.up.square.fill", color: .purple,
          gradient: [.purple, .indigo], description: "Christ's victory over death"),
        TopicItem(
          name: "Repentance", keyword: "repentance", icon: "arrow.uturn.left", color: .orange,
          gradient: [.orange, .yellow], description: "Turning away from sin"),
      ]
    ),
    TopicCategory(
      name: "Peace & Joy",
      icon: "sun.max.fill",
      color: .yellow,
      topics: [
        TopicItem(
          name: "Joy", keyword: "joy", icon: "sun.max.fill", color: .yellow,
          gradient: [.yellow, .orange], description: "Deep happiness and spiritual delight"),
        TopicItem(
          name: "Peace", keyword: "peace", icon: "leaf.fill", color: .mint,
          gradient: [.mint, .green], description: "Tranquility and harmony with God"),
        TopicItem(
          name: "Comfort", keyword: "comfort", icon: "heart.text.square.fill", color: .cyan,
          gradient: [.cyan, .blue], description: "Solace in times of trouble"),
        TopicItem(
          name: "Hope", keyword: "hope", icon: "sunrise.fill", color: .orange,
          gradient: [.orange, .yellow], description: "Looking forward with confidence"),
        TopicItem(
          name: "Encouragement", keyword: "encourage", icon: "arrow.up.heart.fill", color: .pink,
          gradient: [.pink, .red], description: "Strength and motivation in difficult times"),
        TopicItem(
          name: "Gratitude", keyword: "thanks", icon: "hands.clap.fill", color: .yellow,
          gradient: [.yellow, .orange], description: "Thankfulness for God's blessings"),
        TopicItem(
          name: "Contentment", keyword: "contentment", icon: "smiley", color: .green,
          gradient: [.green, .mint], description: "Satisfaction in God's provision"),
        TopicItem(
          name: "Rest", keyword: "rest", icon: "bed.double.fill", color: .blue,
          gradient: [.blue, .indigo], description: "Finding peace in God's presence"),
      ]
    ),
  ]

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        LazyVStack(spacing: 24) {
          // Introduction section
          VStack(spacing: 16) {
            HStack {
              Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)
              Text("Explore by Theme")
                .font(.headline)
                .fontWeight(.semibold)
              Spacer()
            }

            Text("Discover what the Bible says about life's important topics")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.horizontal)
          .padding(.top)

          // Topic categories
          ForEach(topicCategories, id: \.name) { category in
            TopicCategorySection(category: category, path: $path)
          }

          Spacer(minLength: 40)
        }
      }
      .background(Color(.systemGroupedBackground))
      .navigationDestination(for: Topic.self) { topic in
        TopicDetailView(topic: topic)
      }
    }
  }
}

// MARK: - Topic Category Model
struct TopicCategory {
  let name: String
  let icon: String
  let color: Color
  let topics: [TopicItem]
}

// MARK: - Topic Category Section
struct TopicCategorySection: View {
  let category: TopicCategory
  @Binding var path: NavigationPath

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Category header
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(category.color.opacity(0.1))
            .frame(width: 40, height: 40)

          Image(systemName: category.icon)
            .font(.system(size: 18))
            .foregroundColor(category.color)
        }

        Text(category.name)
          .font(.title3)
          .fontWeight(.semibold)

        Spacer()
      }
      .padding(.horizontal)

      // Topics in this category - with padding to prevent clipping
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          // Add leading spacer for padding
          Color.clear.frame(width: 1)

          ForEach(category.topics, id: \.id) { topic in
            CompactTopicCard(topic: topic) {
              path.append(topic.asLegacyTopic)
            }
          }

          // Add trailing spacer for padding
          Color.clear.frame(width: 1)
        }
        .padding(.vertical, 16)  // Padding to prevent shadow clipping
      }
      .padding(.horizontal, -1)  // Compensate for spacers
    }
  }
}

// MARK: - Compact Topic Card
struct CompactTopicCard: View {
  let topic: TopicItem
  let action: () -> Void
  @State private var isPressed = false
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    Button(action: action) {
      VStack(spacing: 12) {
        // Icon
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(
              LinearGradient(
                gradient: Gradient(colors: topic.gradient),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
      .frame(width: 38, height: 38)

          Image(systemName: topic.icon)
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.white)
        }

        // Title
        VStack(spacing: 4) {
          Text(topic.name)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(1)

          Text(topic.description)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
        }
      }
      .frame(width: 90, height: 105)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(
            colorScheme == .dark
              ? Color.white.opacity(0.1)
              : Color.gray.opacity(0.15),
            lineWidth: 1
          )
      )
      .shadow(
        color: colorScheme == .dark
          ? topic.color.opacity(0.3)
          : Color.black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 4
      )
      .scaleEffect(isPressed ? 0.95 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    .buttonStyle(PlainButtonStyle())
    .onLongPressGesture(
      minimumDuration: 0, maximumDistance: .infinity,
      pressing: { pressing in
        withAnimation(.easeInOut(duration: 0.1)) {
          isPressed = pressing
        }
      }, perform: {})
  }
}

// MARK: - Traditional Bible View (Your existing BibleStudyView)
struct TraditionalBibleView: View {
  @State private var books: [BookInfo] = []
  @State private var isLoading = true

  // Use singleton Bible manager
  @StateObject private var bibleManager = BibleManager.shared

  // Optimized book info structure
  struct BookInfo: Identifiable {
    let id = UUID()
    let name: String
    let chapterCount: Int
    let order: Int
  }

  var body: some View {
    VStack(spacing: 0) {
      // Introduction section
      HStack(alignment: .top, spacing: 8) {
        Image(systemName: "books.vertical.fill")
          .foregroundColor(.green)
        VStack(alignment: .leading, spacing: 2) {
          Text("Browse by Book")
            .font(.headline)
            .fontWeight(.semibold)
          Text("Authorized King James Version")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        Spacer()
      }
      .padding()
      .background(Color(.systemGroupedBackground))

      // Content
      Group {
        if bibleManager.isLoading {
          VStack(spacing: 20) {
            ProgressView()
              .scaleEffect(1.2)

            Text("Loading Bible...")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(.systemGroupedBackground))
        } else if let errorMessage = bibleManager.errorMessage {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
              .font(.largeTitle)
              .foregroundColor(.red)
            Text("Error Loading Bible")
              .font(.headline)
            Text(errorMessage)
              .foregroundColor(.red)
              .multilineTextAlignment(.center)
              .padding(.horizontal)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color(.systemGroupedBackground))
        } else {
          // Books list - Optimized with LazyVStack
          List {
            ForEach(books) { bookInfo in
              NavigationLink(
                destination: BookDetailView(bookName: bookInfo.name)
              ) {
                HStack {
                  Image(systemName: "book.closed.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                  VStack(alignment: .leading, spacing: 2) {
                    Text(bookInfo.name)
                      .font(.body)
                      .fontWeight(.medium)

                    Text("\(bookInfo.chapterCount) chapter\(bookInfo.chapterCount == 1 ? "" : "s")")
                      .font(.caption)
                      .foregroundColor(.secondary)
                  }

                  Spacer()
                }
                .padding(.vertical, 4)
              }
              .listRowBackground(Color(.secondarySystemGroupedBackground))
            }
          }
          .listStyle(PlainListStyle())
          .scrollContentBackground(.hidden)
          .background(Color(.systemGroupedBackground))
        }
      }
    }
    .background(Color(.systemGroupedBackground))
    .onAppear {
      loadBooksFromManager()
    }
    .onChange(of: bibleManager.isLoaded) { _, isLoaded in
      if isLoaded {
        loadBooksFromManager()
      }
    }
  }

  func loadBooksFromManager() {
    guard bibleManager.isLoaded else { return }

    let booksInfo = bibleManager.getBooksInfo()
    books = booksInfo.map { bookInfo in
      BookInfo(
        name: bookInfo.name,
        chapterCount: bookInfo.chapterCount,
        order: bookInfo.order
      )
    }
  }
}

// MARK: - Book Detail View (from BibleStudyViews.swift)
struct BookDetailView: View {
  let bookName: String
  @State private var chapters: [ChapterInfo] = []
  @State private var isLoading = true

  // Use singleton Bible manager
  @StateObject private var bibleManager = BibleManager.shared

  // Optimized chapter info structure
  struct ChapterInfo: Identifiable {
    let id: Int
    let chapter: Int
    let verseCount: Int

    init(chapter: Int, verseCount: Int) {
      self.id = chapter
      self.chapter = chapter
      self.verseCount = verseCount
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      // Book header
      VStack(spacing: 8) {
        Text(bookName)
          .font(.largeTitle)
          .fontWeight(.bold)

        if !chapters.isEmpty {
          Text("\(chapters.count) Chapter\(chapters.count == 1 ? "" : "s")")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
      }
      .padding()
      .frame(maxWidth: .infinity)
      .background(Color(.systemGroupedBackground))

      // Content
      if isLoading || bibleManager.isLoading {
        VStack(spacing: 16) {
          ProgressView()
          Text("Loading chapters...")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
      } else {
        // Chapters list - Optimized
        List {
          ForEach(chapters) { chapterInfo in
            NavigationLink(
              destination: ChapterDetailView(
                bookName: bookName,
                chapter: chapterInfo.chapter
              )
            ) {
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  Text("Chapter \(chapterInfo.chapter)")
                    .font(.headline)

                  Text("\(chapterInfo.verseCount) verse\(chapterInfo.verseCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                Spacer()
              }
              .padding(.vertical, 4)
            }
            .listRowBackground(Color(.secondarySystemGroupedBackground))
          }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      loadChaptersFromManager()
    }
    .onChange(of: bibleManager.isLoaded) { _, isLoaded in
      if isLoaded {
        loadChaptersFromManager()
      }
    }
  }

  private func loadChaptersFromManager() {
    guard bibleManager.isLoaded else { return }

    isLoading = true

    DispatchQueue.global(qos: .userInitiated).async {
      let chaptersInfo = bibleManager.getChaptersForBook(bookName)

      let processedChapters = chaptersInfo.map { chapterInfo in
        ChapterInfo(chapter: chapterInfo.chapter, verseCount: chapterInfo.verseCount)
      }

      DispatchQueue.main.async {
        self.chapters = processedChapters
        self.isLoading = false
      }
    }
  }
}

// MARK: - Chapter Detail View (from BibleStudyViews.swift)
struct ChapterDetailView: View {
  let bookName: String
  let chapter: Int
  @State private var verses: [Verse] = []
  @State private var isLoading = true
  @State private var selectedVerseForCard: Verse?
  @State private var showCopyToast = false

  // Use singleton Bible manager
  @StateObject private var bibleManager = BibleManager.shared

  @EnvironmentObject var savedVersesManager: SavedVersesManager
  @EnvironmentObject var settings: UserSettings

  var body: some View {
    Group {
      if isLoading || bibleManager.isLoading {
        VStack(spacing: 16) {
          ProgressView()
          Text("Loading verses...")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 0) {
            // Chapter header
            VStack(spacing: 8) {
              Text("\(bookName)")
                .font(.subheadline)
                .foregroundColor(.secondary)

              Text("Chapter \(chapter)")
                .font(.title)
                .fontWeight(.bold)
            }
            .padding()
            .frame(maxWidth: .infinity)

            Divider()

            // Verses - Using LazyVStack for better performance
            LazyVStack(alignment: .leading, spacing: 16) {
              ForEach(verses) { verse in
                VerseRow(
                  verse: verse,
                  onShare: { selectedVerseForCard = verse },
                  onCopy: {
                    let copyText = "\(verse.text.cleanVerse)\n\(verse.book_name) \(verse.chapter):\(verse.verse)"
                    UIPasteboard.general.string = copyText
                    showCopyToast = true
                  },
                  onBookmark: { savedVersesManager.toggleVerseSaved(verse) }
                )
                .environmentObject(settings)
                .environmentObject(savedVersesManager)

                if verse.id != verses.last?.id {
                  Divider()
                    .padding(.leading, 50)
                }
              }
            }
            .padding(.vertical)
            .background(Color(.secondarySystemGroupedBackground))

            // Footer
            VStack(spacing: 4) {
              Divider()
              Text("Authorized King James Version")
                .font(.caption)
                .foregroundColor(.secondary)
              Text("Public Domain")
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding()
          }
        }
        .background(Color(.systemGroupedBackground))
      }
    }
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      loadVersesFromManager()
    }
    .onChange(of: bibleManager.isLoaded) { _, isLoaded in
      if isLoaded {
        loadVersesFromManager()
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
  }

  private func loadVersesFromManager() {
    guard bibleManager.isLoaded else { return }

    isLoading = true

    DispatchQueue.global(qos: .userInitiated).async {
      // Use BibleManager's optimized verse retrieval
      let chapterVerses = bibleManager.getVersesForChapter(bookName: bookName, chapter: chapter)

      DispatchQueue.main.async {
        self.verses = chapterVerses
        self.isLoading = false
      }
    }
  }
}

// MARK: - Verse Row Component (from BibleStudyViews.swift)
struct VerseRow: View {
  let verse: Verse
  let onShare: () -> Void
  let onCopy: () -> Void
  let onBookmark: () -> Void

  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedVersesManager: SavedVersesManager

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // Verse number
      Text("\(verse.verse)")
        .font(.footnote)
        .fontWeight(.semibold)
        .foregroundColor(.blue)
        .frame(minWidth: 25, alignment: .center)

      // Verse text
      Text(verse.text.cleanVerse)
        .font(.system(size: settings.fontSize))
        .fixedSize(horizontal: false, vertical: true)

      Spacer(minLength: 0)

      // Action buttons
      HStack(spacing: 12) {
        // Share button
        Button(action: onShare) {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 14))
            .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())

        // Copy button
        Button(action: onCopy) {
          Image(systemName: "doc.on.doc")
            .font(.system(size: 14))
            .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())

        // Bookmark button
        Button(action: onBookmark) {
          Image(
            systemName: savedVersesManager.isVerseSaved(verse)
              ? "bookmark.fill" : "bookmark"
          )
          .font(.system(size: 14))
          .foregroundColor(savedVersesManager.isVerseSaved(verse) ? .blue : .gray)
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding(.horizontal)
  }
}
