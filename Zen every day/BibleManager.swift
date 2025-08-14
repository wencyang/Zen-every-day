import Combine
import SwiftUI
import UIKit
import CryptoKit

// MARK: - Singleton Bible Manager
class BibleManager: ObservableObject {
  static let shared = BibleManager()

  @Published var bible: Bible?
  @Published var isLoaded = false
  @Published var isLoading = false
  @Published var errorMessage: String?

  // Optimization caches - Made private and more efficient
  private var verseLookupCache: [String: Verse] = [:]
  private var bookCache: [String: [Verse]] = [:]
  private var searchTrie: SearchTrie = SearchTrie()  // More efficient than word-to-verses mapping
  private var isSearchIndexBuilt = false
  private var isCacheBuilt = false
  // Additional caches
  private var booksInfoCache: [(name: String, chapterCount: Int, order: Int)]?
  private var chaptersCache: [String: [(chapter: Int, verseCount: Int)]] = [:]

  // Prevent multiple simultaneous loads
  private var loadingTask: Task<Void, Never>?

  // Search performance improvements
  private let searchQueue = DispatchQueue(label: "bible.search", qos: .userInitiated)
  private var lastSearchTask: Task<[Verse], Never>?

  // Cache file for faster subsequent loads
  private let bibleCacheURL: URL = {
    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    return caches.appendingPathComponent("BibleCache.plist")
  }()
  private let bibleCacheHashKey = "bibleCacheHash"

  // Book name mappings for normalization
  private let bookNameMappings: [String: String] = [
    "1st Chronicles": "1 Chronicles",
    "2nd Chronicles": "2 Chronicles",
    "1st Corinthians": "1 Corinthians",
    "2nd Corinthians": "2 Corinthians",
    "1st Kings": "1 Kings",
    "2nd Kings": "2 Kings",
    "1st Peter": "1 Peter",
    "2nd Peter": "2 Peter",
    "1st Samuel": "1 Samuel",
    "2nd Samuel": "2 Samuel",
    "1st Thessalonians": "1 Thessalonians",
    "2nd Thessalonians": "2 Thessalonians",
    "1st Timothy": "1 Timothy",
    "2nd Timothy": "2 Timothy",
    "1st John": "1 John",
    "2nd John": "2 John",
    "3rd John": "3 John",
    "Revelation of John": "Revelation",
    "Song of Solomon": "Song of Songs",
    "Psalm": "Psalms",
  ]

  private init() {}

  /// Ensure the Bible is loaded. This will kick off the asynchronous load
  /// if it hasn't already started.
  func loadBibleIfNeeded() {
    guard bible == nil && !isLoading else { return }
    loadBibleAsync()
  }

  // MARK: - Bible Loading
  private func loadBibleAsync() {
    guard loadingTask == nil, !isLoading && bible == nil else { return }

    DispatchQueue.main.async {
      self.isLoading = true
      self.errorMessage = nil
    }

    loadingTask = Task {
      await loadBible()
    }
  }

  @MainActor
  private func loadBible() async {
    guard let dataAsset = NSDataAsset(name: "kjv") else {
      self.errorMessage = "Could not load kjv asset."
      self.isLoading = false
      self.loadingTask = nil
      return
    }

    let assetData = dataAsset.data
    let currentHash = sha256(of: assetData)

    if
      let cachedHash = UserDefaults.standard.string(forKey: bibleCacheHashKey),
      cachedHash == currentHash,
      let cachedData = try? Data(contentsOf: bibleCacheURL),
      let cachedBible = try? PropertyListDecoder().decode(Bible.self, from: cachedData)
    {
      self.bible = cachedBible
      self.isLoaded = true
      self.isLoading = false
      self.loadingTask = nil

      #if DEBUG
        print("✅ BibleManager: Loaded Bible from cache with \(cachedBible.verses.count) verses")
      #endif

      Task.detached(priority: .high) {
        await self.buildOptimizedCaches(for: cachedBible)
      }
      return
    }

    do {
      let loadedBible = try await Task.detached(priority: .userInitiated) {
        let decoder = JSONDecoder()
        return try decoder.decode(Bible.self, from: assetData)
      }.value

      self.bible = loadedBible
      self.isLoaded = true
      self.isLoading = false
      self.loadingTask = nil

      #if DEBUG
        print("✅ BibleManager: Successfully loaded Bible with \(loadedBible.verses.count) verses")
      #endif

      // Persist cache in background
      Task.detached(priority: .utility) { [
        bibleCacheURL = self.bibleCacheURL,
        bibleCacheHashKey = self.bibleCacheHashKey
      ] in
        if let encoded = try? PropertyListEncoder().encode(loadedBible) {
          try? encoded.write(to: bibleCacheURL, options: .atomic)
          UserDefaults.standard.set(currentHash, forKey: bibleCacheHashKey)
        }
      }

      // Build caches in background with higher priority
      Task.detached(priority: .high) {
        await self.buildOptimizedCaches(for: loadedBible)
      }

    } catch {
      self.errorMessage = "Failed to decode Bible: \(error.localizedDescription)"
      self.isLoading = false
      self.loadingTask = nil
    }
  }

  // MARK: - Optimized Cache Building
  private func buildOptimizedCaches(for bible: Bible) async {
    guard !isCacheBuilt else { return }

    let startTime = CFAbsoluteTimeGetCurrent()

    // Build all caches in parallel
    async let verseCache = buildVerseLookupCache(verses: bible.verses)
    async let bookCache = buildBookCache(verses: bible.verses)
    async let searchIndex = buildOptimizedSearchIndex(verses: bible.verses)

    let (verseLookup, bookLookup, trie) = await (verseCache, bookCache, searchIndex)

    await MainActor.run {
      self.verseLookupCache = verseLookup
      self.bookCache = bookLookup
      self.searchTrie = trie
      self.booksInfoCache = bookLookup.map { key, verses in
        let chapters = Set(verses.map { $0.chapter })
        let order = verses.first?.book ?? 0
        return (name: key, chapterCount: chapters.count, order: order)
      }.sorted { $0.order < $1.order }
      self.chaptersCache = bookLookup.reduce(into: [:]) { result, entry in
        let (bookName, verses) = entry
        var counts: [Int: Int] = [:]
        for v in verses { counts[v.chapter, default: 0] += 1 }
        let chapterInfo = counts.map { (chapter: $0.key, verseCount: $0.value) }.sorted { $0.chapter < $1.chapter }
        result[bookName] = chapterInfo
        let normalized = self.normalizeBookName(bookName)
        if normalized != bookName {
          result[normalized] = chapterInfo
        }
      }
      self.isCacheBuilt = true
      self.isSearchIndexBuilt = true
    }

    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime

    #if DEBUG
      print("✅ BibleManager: Built optimized caches in \(String(format: "%.2f", timeElapsed))s")
      print("   - \(verseLookup.count) verses cached")
      print("   - \(bookLookup.count) books cached")
      print("   - Search trie built with \(trie.nodeCount) nodes")
    #endif
  }

  private func buildVerseLookupCache(verses: [Verse]) async -> [String: Verse] {
    var cache: [String: Verse] = [:]
    cache.reserveCapacity(verses.count)  // Pre-allocate capacity

    for verse in verses {
      let key = "\(verse.book_name)_\(verse.chapter)_\(verse.verse)"
      cache[key] = verse
    }

    return cache
  }

  private func buildBookCache(verses: [Verse]) async -> [String: [Verse]] {
    var cache: [String: [Verse]] = [:]

    // Group verses by book more efficiently
    let grouped = Dictionary(grouping: verses) { $0.book_name }

    for (bookName, bookVerses) in grouped {
      cache[bookName] = bookVerses.sorted { verse1, verse2 in
        if verse1.chapter != verse2.chapter {
          return verse1.chapter < verse2.chapter
        }
        return verse1.verse < verse2.verse
      }
    }

    return cache
  }

  private func buildOptimizedSearchIndex(verses: [Verse]) async -> SearchTrie {
    let trie = SearchTrie()
    let chunkSize = 1000

    for chunk in verses.chunked(into: chunkSize) {
      for verse in chunk {
        let words = verse.text.cleanVerse.lowercased()
          .components(separatedBy: CharacterSet.alphanumerics.inverted)
          .filter { !$0.isEmpty && $0.count > 2 }

        for word in words {
          trie.insert(word: word, verse: verse)
        }
      }

      // Allow other tasks to run periodically every 5 chunks
      await Task.yield()
    }

    return trie
  }

  // MARK: - Public Methods

  /// Get Bible instance (blocking if not loaded)
  func getBible() -> Bible? {
    return bible
  }

  /// Wait for Bible to load with completion handler
  func whenReady(completion: @escaping (Bible?) -> Void) {
    if let bible = bible {
      completion(bible)
    } else if let error = errorMessage {
      print("❌ BibleManager error: \(error)")
      completion(nil)
    } else {
      // Wait for loading to complete
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.whenReady(completion: completion)
      }
    }
  }
  func searchVerses(query: String, limit: Int = 100) async -> [Verse] {
    // Cancel previous search
    lastSearchTask?.cancel()

    guard let bible = bible, !query.isEmpty, isSearchIndexBuilt else {
      return []
    }

    let searchQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    lastSearchTask = Task {
      // Use trie for single words, optimized phrase search for multiple words
      let words = searchQuery.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }

      if words.count == 1, let word = words.first {
        // Single word search using trie
        return Array(searchTrie.search(word: word).prefix(limit))
      } else {
        // Multi-word search with optimized algorithm
        return await optimizedPhraseSearch(words: words, verses: bible.verses, limit: limit)
      }
    }

    return await lastSearchTask?.value ?? []
  }

  private func optimizedPhraseSearch(words: [String], verses: [Verse], limit: Int) async -> [Verse]
  {
    var results: [Verse] = []
    let searchTerms = words.map { $0.lowercased() }

    // Process verses in chunks to allow for cancellation
    for chunk in verses.chunked(into: 500) {
      if Task.isCancelled { break }

      for verse in chunk {
        let verseText = verse.text.cleanVerse.lowercased()

        // Check if all search terms are present
        let containsAllTerms = searchTerms.allSatisfy { term in
          verseText.contains(term)
        }

        if containsAllTerms {
          results.append(verse)
          if results.count >= limit {
            return results
          }
        }
      }

      // Yield control periodically
      await Task.yield()
    }

    return results
  }

  // MARK: - Synchronous API (for backward compatibility)
  func searchVerses(query: String, limit: Int = 100) -> [Verse] {
    // Fallback synchronous search for immediate needs
    guard let bible = bible, !query.isEmpty else { return [] }

    let searchQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

    if isSearchIndexBuilt {
      let words = searchQuery.components(separatedBy: .whitespacesAndNewlines)
        .filter { !$0.isEmpty }

      if words.count == 1, let word = words.first {
        return Array(searchTrie.search(word: word).prefix(limit))
      }
    }

    // Fallback to linear search
    return Array(
      bible.verses
        .filter { verse in
          verse.text.cleanVerse.localizedCaseInsensitiveContains(searchQuery)
        }
        .prefix(limit)
    )
  }

  // MARK: - Existing optimized methods (unchanged)
  func findVerse(bookName: String, chapter: Int, verseNumber: Int) -> Verse? {
    guard isCacheBuilt else {
      return findVerseLinear(bookName: bookName, chapter: chapter, verseNumber: verseNumber)
    }

    let cacheKey = "\(bookName)_\(chapter)_\(verseNumber)"
    if let cachedVerse = verseLookupCache[cacheKey] {
      return cachedVerse
    }

    let normalizedBookName = normalizeBookName(bookName)
    let normalizedCacheKey = "\(normalizedBookName)_\(chapter)_\(verseNumber)"
    if let cachedVerse = verseLookupCache[normalizedCacheKey] {
      verseLookupCache[cacheKey] = cachedVerse
      return cachedVerse
    }

    return findVerseLinear(bookName: bookName, chapter: chapter, verseNumber: verseNumber)
  }

  private func findVerseLinear(bookName: String, chapter: Int, verseNumber: Int) -> Verse? {
    guard let bible = bible else { return nil }

    if let verse = bible.verses.first(where: {
      $0.book_name == bookName && $0.chapter == chapter && $0.verse == verseNumber
    }) {
      let cacheKey = "\(bookName)_\(chapter)_\(verseNumber)"
      verseLookupCache[cacheKey] = verse
      return verse
    }

    let normalizedBookName = normalizeBookName(bookName)
    if let verse = bible.verses.first(where: {
      $0.book_name == normalizedBookName && $0.chapter == chapter && $0.verse == verseNumber
    }) {
      let normalizedCacheKey = "\(normalizedBookName)_\(chapter)_\(verseNumber)"
      verseLookupCache[normalizedCacheKey] = verse
      return verse
    }

    return nil
  }

  func getVersesForBook(_ bookName: String) -> [Verse] {
    if let cachedVerses = bookCache[bookName] {
      return cachedVerses
    }

    let normalizedBookName = normalizeBookName(bookName)
    if let cachedVerses = bookCache[normalizedBookName] {
      bookCache[bookName] = cachedVerses
      return cachedVerses
    }

    return []
  }

  func getBooksInfo() -> [(name: String, chapterCount: Int, order: Int)] {
    if let cached = booksInfoCache { return cached }

    guard let bible = bible else { return [] }

    var bookData: [String: (order: Int, chapters: Set<Int>)] = [:]

    for verse in bible.verses {
      if var existingData = bookData[verse.book_name] {
        existingData.chapters.insert(verse.chapter)
        bookData[verse.book_name] = existingData
      } else {
        bookData[verse.book_name] = (order: verse.book, chapters: Set([verse.chapter]))
      }
    }

    let info = bookData.map { (name, data) in
      (name: name, chapterCount: data.chapters.count, order: data.order)
    }.sorted { $0.order < $1.order }

    booksInfoCache = info
    return info
  }

  func getChaptersForBook(_ bookName: String) -> [(chapter: Int, verseCount: Int)] {
    if let cached = chaptersCache[bookName] { return cached }
    let normalized = normalizeBookName(bookName)
    if let cached = chaptersCache[normalized] {
      chaptersCache[bookName] = cached
      return cached
    }

    let verses = getVersesForBook(bookName)
    var chapterCounts: [Int: Int] = [:]

    for verse in verses {
      chapterCounts[verse.chapter, default: 0] += 1
    }

    let info = chapterCounts.map { (chapter, count) in
      (chapter: chapter, verseCount: count)
    }.sorted { $0.chapter < $1.chapter }

    chaptersCache[bookName] = info
    return info
  }

  func getVersesForChapter(bookName: String, chapter: Int) -> [Verse] {
    let bookVerses = getVersesForBook(bookName)
    return bookVerses.filter { $0.chapter == chapter }.sorted { $0.verse < $1.verse }
  }

  // MARK: - Private Helpers
  private func normalizeBookName(_ bookName: String) -> String {
    if let mapped = bookNameMappings[bookName] {
      return mapped
    }

    let trimmed = bookName.trimmingCharacters(in: .whitespacesAndNewlines)
    if let mapped = bookNameMappings[trimmed] {
      return mapped
    }

    return trimmed
  }

  private func sha256(of data: Data) -> String {
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
  }

  // MARK: - Memory Management
  func clearCaches() {
    verseLookupCache.removeAll()
    bookCache.removeAll()
    searchTrie.clear()
    booksInfoCache = nil
    chaptersCache.removeAll()
    isSearchIndexBuilt = false
    isCacheBuilt = false
  }

  deinit {
    loadingTask?.cancel()
    clearCaches()
  }
}

// MARK: - Search Trie Implementation
private class SearchTrie {
  private class TrieNode {
    var children: [Character: TrieNode] = [:]
    var verses: Set<VerseID> = []
    var isEndOfWord = false
  }

  private struct VerseID: Hashable {
    let bookName: String
    let chapter: Int
    let verse: Int

    init(_ verse: Verse) {
      self.bookName = verse.book_name
      self.chapter = verse.chapter
      self.verse = verse.verse
    }
  }

  private let root = TrieNode()
  private var verseMap: [VerseID: Verse] = [:]

  var nodeCount: Int {
    countNodes(from: root)
  }

  private func countNodes(from node: TrieNode) -> Int {
    1 + node.children.values.reduce(0) { $0 + countNodes(from: $1) }
  }

  func insert(word: String, verse: Verse) {
    let verseID = VerseID(verse)
    verseMap[verseID] = verse

    var current = root
    for char in word.lowercased() {
      if current.children[char] == nil {
        current.children[char] = TrieNode()
      }
      current = current.children[char]!
      current.verses.insert(verseID)
    }
    current.isEndOfWord = true
  }

  func search(word: String) -> [Verse] {
    var current = root

    for char in word.lowercased() {
      guard let node = current.children[char] else {
        return []
      }
      current = node
    }

    return current.verses.compactMap { verseMap[$0] }
  }

  func clear() {
    root.children.removeAll()
    verseMap.removeAll()
  }
}

// MARK: - Convenience Extensions
extension BibleManager {
  var bibleLoadedPublisher: AnyPublisher<Bible, Never> {
    $bible
      .compactMap { $0 }
      .first()
      .eraseToAnyPublisher()
  }
}

// MARK: - Array Extension for Chunking
extension Array {
  func chunked(into size: Int) -> [[Element]] {
    return stride(from: 0, to: count, by: size).map {
      Array(self[$0..<Swift.min($0 + size, count)])
    }
  }
}
