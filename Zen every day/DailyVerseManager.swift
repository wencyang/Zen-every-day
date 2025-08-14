import Combine
import SwiftUI
import UIKit

// Model to hold a saved daily verse entry.
struct DailyVerseEntry: Codable, Identifiable {
  var id: String { date }  // Unique by date
  let date: String  // Format: "yyyy-MM-dd"
  let reference: String
  let text: String
}

class DailyVerseManager: ObservableObject {
  @Published var dailyVerse: Verse?
  @Published var errorMessage: String?

  // Cache keys
  private let todayVerseKey = "cachedTodayVerse"
  private let todayDateKey = "cachedTodayDate"

  // Cache for daily verse references - loaded lazily
  private var _dailyVerseReferences: [String]?
  private var dailyVerseReferences: [String] {
    if let cached = _dailyVerseReferences {
      return cached
    }

    guard let dataAsset = NSDataAsset(name: "DailyVerseReferences") else {
      self.errorMessage = "Could not load DailyVerseReferences asset."
      return []
    }

    do {
      let references = try JSONDecoder().decode([String].self, from: dataAsset.data)
      _dailyVerseReferences = references
      return references
    } catch {
      self.errorMessage = "Failed to decode DailyVerseReferences: \(error)"
      return []
    }
  }

  private let historyKey = "dailyVerseHistory"
  private var cancellables = Set<AnyCancellable>()

  // Track attempts when computing the daily verse so we can fallback if the
  // Bible fails to load for some reason.
  private var computeRetries = 0
  private let maxComputeRetries = 5

  // Fallback verses in case of any issues
  private let fallbackVerses: [(reference: String, bookName: String, chapter: Int, verse: Int)] = [
    ("John 3:16", "John", 3, 16),
    ("Psalms 23:1", "Psalms", 23, 1),
    ("Proverbs 3:5", "Proverbs", 3, 5),
    ("Romans 8:28", "Romans", 8, 28),
    ("Philippians 4:13", "Philippians", 4, 13),
    ("Isaiah 40:31", "Isaiah", 40, 31),
    ("Matthew 6:33", "Matthew", 6, 33)
  ]

  init() {
    // Ensure the Bible begins loading so the verse can be computed promptly
    BibleManager.shared.loadBibleIfNeeded()

    // FIRST: Try to load cached verse immediately
    loadCachedVerse()

    // THEN: Subscribe to Bible loading to verify/update if needed
    BibleManager.shared.$isLoaded
      .dropFirst()  // Skip the initial false value
      .filter { $0 }  // Only respond to true values
      .sink { [weak self] _ in
        // Verify the cached verse or compute new one if needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          self?.verifyOrUpdateDailyVerse()
        }
      }
      .store(in: &cancellables)

    // If Bible is already loaded, verify immediately
    if BibleManager.shared.isLoaded {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.verifyOrUpdateDailyVerse()
      }
    }
  }

  /// Load cached verse immediately on init
  private func loadCachedVerse() {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())

    // Check if we have a cached verse for today
    if let cachedDate = UserDefaults.standard.string(forKey: todayDateKey),
      cachedDate == todayString,
      let cachedData = UserDefaults.standard.data(forKey: todayVerseKey),
      let cachedVerse = try? JSONDecoder().decode(CachedVerse.self, from: cachedData)
    {

      // Create a Verse object from cached data
      self.dailyVerse = Verse(
        book_name: cachedVerse.book_name,
        book: cachedVerse.book,
        chapter: cachedVerse.chapter,
        verse: cachedVerse.verse,
        text: cachedVerse.text
      )

      debugLog("DEBUG: Loaded cached verse immediately")
    }
  }

  /// Cache the current verse for instant display next time
  private func cacheCurrentVerse(_ verse: Verse) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())

    let cachedVerse = CachedVerse(
      book_name: verse.book_name,
      book: verse.book,
      chapter: verse.chapter,
      verse: verse.verse,
      text: verse.text
    )

    if let data = try? JSONEncoder().encode(cachedVerse) {
      UserDefaults.standard.set(data, forKey: todayVerseKey)
      UserDefaults.standard.set(todayString, forKey: todayDateKey)
    }
  }

  /// Verify cached verse or compute new one
  private func verifyOrUpdateDailyVerse() {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())

    // If we already have today's verse displayed, just verify it's correct
    if dailyVerse != nil,
      let cachedDate = UserDefaults.standard.string(forKey: todayDateKey),
      cachedDate == todayString
    {
      // We already have today's verse, no need to recompute
      debugLog("DEBUG: Today's verse already loaded and cached")
      return
    }

    // Otherwise, compute the daily verse
    setDailyVerse()
  }

  /// Computes a stable hash by summing Unicode scalar values.
  private func stableHash(_ s: String) -> Int {
    return s.unicodeScalars.map { Int($0.value) }.reduce(0, +)
  }

  /// Checks history for today's entry; if none, computes and saves a new daily verse.
  func setDailyVerse() {
    // Reset the retry counter for a fresh attempt each day.
    computeRetries = 0

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())

    // Check if there's already an entry for today in history.
    let history = loadHistory()
    if let entry = history.first(where: { $0.date == todayString }) {
      debugLog("DEBUG: Found saved entry for today: \(entry.reference)")
      // Parse the reference from the saved entry.
      parseAndSetVerse(from: entry, todayString: todayString)
      return
    } else {
      debugLog("DEBUG: No saved entry for today, computing new daily verse")
      computeAndSaveDailyVerse(todayString: todayString)
    }
  }

  private func parseAndSetVerse(from entry: DailyVerseEntry, todayString: String) {
    // Parse saved reference like "John 3:16" or "1 Chronicles 29:11"
    if let (bookName, chapter, verseNumber) = parseReference(entry.reference) {
      // Try to find the verse with potential book name variations
      if let foundVerse = findVerseWithVariations(
        bookName: bookName, chapter: chapter, verseNumber: verseNumber)
      {
        dailyVerse = foundVerse
        cacheCurrentVerse(foundVerse)  // Cache for instant display
        debugLog(
          "DEBUG: Successfully loaded saved daily verse: \(foundVerse.book_name) \(foundVerse.chapter):\(foundVerse.verse)"
        )
        return
      }
    }

    debugLog("DEBUG: Failed to parse saved reference: \(entry.reference)")
    // If we can't find the saved verse, use a fallback
    setFallbackVerse(todayString: todayString)
  }

  /// Computes a new daily verse deterministically using a stable hash and saves it.
  private func computeAndSaveDailyVerse(todayString: String) {
    // Double-check Bible is loaded. If loading repeatedly fails, fall back to a
    // hard coded verse so the user always sees something.
    guard BibleManager.shared.isLoaded else {
      computeRetries += 1
      if computeRetries <= maxComputeRetries && BibleManager.shared.errorMessage == nil {
        debugLog("DEBUG: Bible still not loaded, retrying... (attempt \(computeRetries))")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
          self?.computeAndSaveDailyVerse(todayString: todayString)
        }
      } else {
        debugLog("DEBUG: Bible failed to load after \(computeRetries) attempts, using fallback")
        setFallbackVerse(todayString: todayString)
      }
      return
    }

    // Reset retry count on success
    computeRetries = 0

    guard !dailyVerseReferences.isEmpty else {
      debugLog("DEBUG: dailyVerseReferences is empty, using fallback")
      setFallbackVerse(todayString: todayString)
      return
    }

    // Use a stable hash of today's date string.
    let hashValue = stableHash(todayString)
    let index = hashValue % dailyVerseReferences.count
    let reference = dailyVerseReferences[index]

    debugLog("DEBUG: Selected reference: \(reference) (index: \(index))")

    // Parse the reference
    guard let (bookName, chapter, verseNumber) = parseReference(reference) else {
      debugLog("DEBUG: Invalid reference format: \(reference), using fallback")
      setFallbackVerse(todayString: todayString)
      return
    }

    debugLog("DEBUG: Parsed - Book: '\(bookName)', Chapter: \(chapter), Verse: \(verseNumber)")

    // Try to find the verse with variations
    if let foundVerse = findVerseWithVariations(
      bookName: bookName, chapter: chapter, verseNumber: verseNumber)
    {
      dailyVerse = foundVerse
      cacheCurrentVerse(foundVerse)  // Cache for instant display
      saveDailyVerse(for: reference, verse: foundVerse)
      debugLog("DEBUG: Successfully found and set daily verse: \(foundVerse.book_name) \(foundVerse.chapter):\(foundVerse.verse)")
    } else {
      debugLog("DEBUG: Could not find verse for reference: \(reference), using fallback")
      setFallbackVerse(todayString: todayString)
    }
  }

  /// Try to find verse with common book name variations
  private func findVerseWithVariations(bookName: String, chapter: Int, verseNumber: Int) -> Verse? {
    // First try the exact name
    if let verse = BibleManager.shared.findVerse(
      bookName: bookName, chapter: chapter, verseNumber: verseNumber)
    {
      return verse
    }
    
    // Common variations to try
    let variations = getBookNameVariations(bookName)
    
    for variation in variations {
      if let verse = BibleManager.shared.findVerse(
        bookName: variation, chapter: chapter, verseNumber: verseNumber)
      {
        debugLog("DEBUG: Found verse using variation: '\(variation)' for original: '\(bookName)'")
        return verse
      }
    }
    
    return nil
  }

  /// Get common variations of book names
  private func getBookNameVariations(_ bookName: String) -> [String] {
    var variations = [bookName]
    
    // Handle "Psalm" vs "Psalms"
    if bookName == "Psalm" {
      variations.append("Psalms")
    } else if bookName == "Psalms" {
      variations.append("Psalm")
    }
    
    // Handle other common variations
    let bookVariations: [String: [String]] = [
      "1 Chronicles": ["1 Chronicles", "1 Chr", "1st Chronicles", "I Chronicles"],
      "2 Chronicles": ["2 Chronicles", "2 Chr", "2nd Chronicles", "II Chronicles"],
      "1 Corinthians": ["1 Corinthians", "1 Cor", "1st Corinthians", "I Corinthians"],
      "2 Corinthians": ["2 Corinthians", "2 Cor", "2nd Corinthians", "II Corinthians"],
      "1 Kings": ["1 Kings", "1 Kgs", "1st Kings", "I Kings"],
      "2 Kings": ["2 Kings", "2 Kgs", "2nd Kings", "II Kings"],
      "1 Peter": ["1 Peter", "1 Pet", "1st Peter", "I Peter"],
      "2 Peter": ["2 Peter", "2 Pet", "2nd Peter", "II Peter"],
      "1 Samuel": ["1 Samuel", "1 Sam", "1st Samuel", "I Samuel"],
      "2 Samuel": ["2 Samuel", "2 Sam", "2nd Samuel", "II Samuel"],
      "1 Thessalonians": ["1 Thessalonians", "1 Thess", "1st Thessalonians", "I Thessalonians"],
      "2 Thessalonians": ["2 Thessalonians", "2 Thess", "2nd Thessalonians", "II Thessalonians"],
      "1 Timothy": ["1 Timothy", "1 Tim", "1st Timothy", "I Timothy"],
      "2 Timothy": ["2 Timothy", "2 Tim", "2nd Timothy", "II Timothy"],
      "1 John": ["1 John", "1 Jn", "1st John", "I John"],
      "2 John": ["2 John", "2 Jn", "2nd John", "II John"],
      "3 John": ["3 John", "3 Jn", "3rd John", "III John"],
      "Revelation": ["Revelation", "Rev", "Revelation of John", "Apocalypse"],
      "Song of Songs": ["Song of Songs", "Song of Solomon", "Canticles"],
    ]
    
    // Check if this book has known variations
    for (_, values) in bookVariations {
      if values.contains(bookName) {
        variations.append(contentsOf: values)
        break
      }
    }
    
    // Remove duplicates
    return Array(Set(variations))
  }

  /// Set a fallback verse when the computed one can't be found
  private func setFallbackVerse(todayString: String) {
    // Clear any error message since we're handling it gracefully
    errorMessage = nil
    
    // Use date-based selection from fallback verses
    let hashValue = stableHash(todayString)
    let index = hashValue % fallbackVerses.count
    let fallback = fallbackVerses[index]
    
    debugLog("DEBUG: Using fallback verse: \(fallback.reference)")
    
    if let foundVerse = BibleManager.shared.findVerse(
      bookName: fallback.bookName,
      chapter: fallback.chapter,
      verseNumber: fallback.verse)
    {
      dailyVerse = foundVerse
      cacheCurrentVerse(foundVerse)
      saveDailyVerse(for: fallback.reference, verse: foundVerse)
      debugLog("DEBUG: Successfully set fallback verse: \(fallback.reference)")
    } else {
      // This should never happen, but if it does, create a manual verse
      debugLog("DEBUG: Even fallback failed, creating manual verse")
      let manualVerse = Verse(
        book_name: "John",
        book: 43, // John's book number
        chapter: 3,
        verse: 16,
        text: "For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life."
      )
      dailyVerse = manualVerse
      cacheCurrentVerse(manualVerse)
    }
  }

  /// Parse a reference string like "John 3:16" or "1 Chronicles 29:11"
  private func parseReference(_ reference: String) -> (bookName: String, chapter: Int, verse: Int)?
  {
    // Find the last colon to separate verse number
    guard let colonIndex = reference.lastIndex(of: ":") else {
      return nil
    }

    let beforeColon = String(reference[..<colonIndex])
    let afterColon = String(reference[reference.index(after: colonIndex)...])

    // Extract verse number
    guard let verseNumber = Int(afterColon.trimmingCharacters(in: .whitespaces)) else {
      return nil
    }

    // Now find the chapter number by looking for the last space before the colon
    let beforeColonTrimmed = beforeColon.trimmingCharacters(in: .whitespaces)

    // Find the last space to separate book name from chapter
    var bookName = ""
    var chapter = 0

    // Work backwards to find where the chapter number starts
    if let lastSpaceIndex = beforeColonTrimmed.lastIndex(of: " ") {
      let potentialChapter = String(
        beforeColonTrimmed[beforeColonTrimmed.index(after: lastSpaceIndex)...])

      if let chapterNumber = Int(potentialChapter) {
        // Found a valid chapter number
        bookName = String(beforeColonTrimmed[..<lastSpaceIndex])
        chapter = chapterNumber
      } else {
        // The last part wasn't a number, might be part of book name
        return nil
      }
    } else {
      // No space found, invalid format
      return nil
    }

    return (bookName: bookName, chapter: chapter, verse: verseNumber)
  }

  private func handleVerseNotFound(bookName: String, chapter: Int, verseNumber: Int) {
    guard let bible = BibleManager.shared.getBible() else { return }

    // Additional debugging: list similar book names
    let availableBooks = Set(bible.verses.map { $0.book_name })
    let similarBooks = availableBooks.filter { availableBook in
      availableBook.lowercased().contains(bookName.lowercased())
        || bookName.lowercased().contains(availableBook.lowercased())
    }

    debugLog("DEBUG: Could not find verse for '\(bookName)'. Similar books available: \(similarBooks)")
    debugLog("DEBUG: Looking for chapter \(chapter), verse \(verseNumber)")

    // Try to find the book with any verse to see if it exists
    let bookExists = bible.verses.contains { $0.book_name.lowercased() == bookName.lowercased() }
    if bookExists {
      let availableChapters = Set(
        bible.verses.filter { $0.book_name.lowercased() == bookName.lowercased() }.map {
          $0.chapter
        })
      let chapterExists = availableChapters.contains(chapter)
      if chapterExists {
        let availableVerses = Set(
          bible.verses.filter {
            $0.book_name.lowercased() == bookName.lowercased() && $0.chapter == chapter
          }.map { $0.verse })
        debugLog("DEBUG: Chapter \(chapter) exists. Available verses: \(availableVerses.sorted())")
      } else {
        debugLog(
          "DEBUG: Chapter \(chapter) not found. Available chapters: \(availableChapters.sorted())")
      }
    }

    // Don't show error to user, just use fallback
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())
    setFallbackVerse(todayString: todayString)
  }

  // MARK: - Persistence for Past 30 Days' Daily Verses

  func saveDailyVerse(for reference: String, verse: Verse) {
    // Perform save operation in background to avoid blocking UI
    DispatchQueue.global(qos: .utility).async { [weak self] in
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      let todayString = formatter.string(from: Date())

      var history = self?.loadHistory() ?? []

      // If there's already an entry for today, do not duplicate.
      if !history.contains(where: { $0.date == todayString }) {
        let newEntry = DailyVerseEntry(
          date: todayString,
          reference: "\(verse.book_name) \(verse.chapter):\(verse.verse)",
          text: verse.text.cleanVerse)
        history.append(newEntry)
        debugLog("DEBUG: Saved daily verse entry for \(todayString)")
      }

      // Keep only entries from the past 30 days.
      history = history.filter { entry in
        if let entryDate = formatter.date(from: entry.date) {
          let diff = Calendar.current.dateComponents([.day], from: entryDate, to: Date()).day ?? 0
          return diff < 30
        }
        return false
      }

      if let data = try? JSONEncoder().encode(history) {
        DispatchQueue.main.async {
          UserDefaults.standard.set(data, forKey: self?.historyKey ?? "dailyVerseHistory")
        }
      }
    }
  }

  func loadHistory() -> [DailyVerseEntry] {
    if let data = UserDefaults.standard.data(forKey: historyKey),
      let history = try? JSONDecoder().decode([DailyVerseEntry].self, from: data)
    {
      return history
    }
    return []
  }
}

// Helper struct for caching
private struct CachedVerse: Codable {
  let book_name: String
  let book: Int
  let chapter: Int
  let verse: Int
  let text: String
}
