import SwiftUI
import UIKit  // For NSDataAsset
import UserNotifications

class NotificationManager: ObservableObject {
  @Published var isNotificationEnabled: Bool = false {
    didSet {
      UserDefaults.standard.set(isNotificationEnabled, forKey: "notificationsEnabled")
      if !isNotificationEnabled {
        // Cancel all notifications if disabled
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
      }
    }
  }

  @Published var notificationTime: Date = Date() {
    didSet {
      UserDefaults.standard.set(notificationTime, forKey: "notificationTime")
      if isNotificationEnabled {
        scheduleNotification()
      }
    }
  }


  @Published var hasPermission: Bool = false

  // Cache for daily verse references - loaded lazily
  private var _dailyVerseReferences: [String]?
  private var dailyVerseReferences: [String] {
    if let cached = _dailyVerseReferences {
      return cached
    }

    guard let dataAsset = NSDataAsset(name: "DailyVerseReferences") else {
      debugLog("DEBUG: Could not load DailyVerseReferences asset")
      return []
    }

    do {
      let references = try JSONDecoder().decode([String].self, from: dataAsset.data)
      _dailyVerseReferences = references
      return references
    } catch {
      debugLog("DEBUG: Failed to decode DailyVerseReferences: \(error)")
      return []
    }
  }

  init() {
    // Load saved preferences
    isNotificationEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")

    if let savedTime = UserDefaults.standard.object(forKey: "notificationTime") as? Date {
      notificationTime = savedTime
    } else {
      // Default to 8:00 AM
      var components = DateComponents()
      components.hour = 8
      components.minute = 0
      notificationTime = Calendar.current.date(from: components) ?? Date()
    }

    // Check current permission status
    checkNotificationPermission()
  }

  func checkNotificationPermission() {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      DispatchQueue.main.async {
        self.hasPermission = settings.authorizationStatus == .authorized
      }
    }
  }

  func requestNotificationPermission(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) {
      granted, error in
      DispatchQueue.main.async {
        self.hasPermission = granted
        completion(granted)
      }
    }
  }

  func scheduleNotification() {
    guard isNotificationEnabled && hasPermission else { return }

    // Ensure the Bible is loaded so we can include verse text
    guard BibleManager.shared.isLoaded else {
      debugLog("DEBUG: BibleManager not loaded, retrying notification scheduling...")
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
        self?.scheduleNotification()
      }
      return
    }

    // Cancel existing notifications
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

    // Create date components for the scheduled time
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: notificationTime)

    // Schedule notification for each of the next 7 days with the appropriate verse
    for dayOffset in 0..<7 {
      guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: Date()) else {
        continue
      }

      let content = UNMutableNotificationContent()
      content.title = "Daily Bible Verse"
      content.sound = .default

      // Get the verse for this specific date
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      let dateString = formatter.string(from: targetDate)

      debugLog("DEBUG: Scheduling notification for date: \(dateString)")

      // Get verse for this date using BibleManager
      if let (verseText, reference) = getVerseForDate(dateString: dateString) {
        debugLog("DEBUG: Found verse for \(dateString): \(reference)")
        // iOS limits notification bodies to a short snippet, so show a simple reminder
        content.body = "Your daily verse is ready"
        content.subtitle = "\(reference) - Tap to read"
        debugLog("DEBUG: Simple notification - Reference: \(reference)")
      } else {
        debugLog("DEBUG: Could not find verse for \(dateString), using fallback")
        content.body = "Open the app to read today's verse"
        content.subtitle = "Daily Bible"
      }

      // Create trigger for this specific date
      var dateComponents = calendar.dateComponents(
        [.year, .month, .day, .hour, .minute], from: targetDate)
      dateComponents.hour = components.hour
      dateComponents.minute = components.minute

      let dateTrigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)

      // Create the request with unique identifier
      let request = UNNotificationRequest(
        identifier: "dailyVerse-\(dateString)", content: content, trigger: dateTrigger)

      // Schedule the notification
      UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
          debugLog("Error scheduling notification for \(dateString): \(error)")
        } else {
          debugLog("DEBUG: Successfully scheduled notification for \(dateString)")
        }
      }
    }

    let minuteString = String(format: "%02d", components.minute ?? 0)
    debugLog("DEBUG: Completed scheduling notifications for the next 7 days at \(components.hour ?? 0):\(minuteString)")
  }

  private func getVerseForDate(dateString: String) -> (String, String)? {
    debugLog("DEBUG: Loading verse for date: \(dateString)")

    // Check if references are loaded
    guard !dailyVerseReferences.isEmpty else {
      debugLog("DEBUG: No daily verse references available")
      return nil
    }

    debugLog("DEBUG: Loaded \(dailyVerseReferences.count) daily verse references")

    // Use the same hash logic as DailyVerseManager
    let hashValue = dateString.unicodeScalars.map { Int($0.value) }.reduce(0, +)
    let index = hashValue % dailyVerseReferences.count
    let reference = dailyVerseReferences[index]

    debugLog("DEBUG: Selected reference: \(reference) (index: \(index))")

    // Use BibleManager to find the verse instead of loading Bible again
    guard BibleManager.shared.isLoaded else {
      debugLog("DEBUG: BibleManager not loaded yet")
      return nil
    }

    debugLog(
      "DEBUG: Using BibleManager with \(BibleManager.shared.getBible()?.verses.count ?? 0) verses")

    // Parse the reference
    let components = reference.components(separatedBy: " ")
    guard components.count >= 2,
      let chapterVerse = components.last,
      let colonIndex = chapterVerse.firstIndex(of: ":")
    else {
      debugLog("DEBUG: Invalid reference format: \(reference)")
      return nil
    }

    let bookName = components.dropLast().joined(separator: " ")
    let chapterStr = chapterVerse[..<colonIndex]
    let verseStr = chapterVerse[chapterVerse.index(after: colonIndex)...]

    guard let chapter = Int(chapterStr) else {
      debugLog("DEBUG: Invalid chapter number in: \(reference)")
      return nil
    }

    // Support verse ranges like "23-24"
    var verseRange: ClosedRange<Int>
    if verseStr.contains("-") {
      let parts = verseStr.split(separator: "-")
      guard parts.count == 2,
        let start = Int(parts[0]),
        let end = Int(parts[1]),
        start <= end
      else {
        debugLog("DEBUG: Invalid verse range in: \(reference)")
        return nil
      }
      verseRange = start...end
    } else if let verseNumber = Int(verseStr) {
      verseRange = verseNumber...verseNumber
    } else {
      debugLog("DEBUG: Invalid verse number in: \(reference)")
      return nil
    }

    debugLog("DEBUG: Searching for - Book: '\(bookName)', Chapter: \(chapter), Verses: \(verseRange.lowerBound)\(verseRange.lowerBound == verseRange.upperBound ? "" : "-\(verseRange.upperBound)")")

    var collectedText: [String] = []
    var finalReference: String?
    for verseNumber in verseRange {
      if let verse = BibleManager.shared.findVerse(
        bookName: bookName, chapter: chapter, verseNumber: verseNumber)
      {
        collectedText.append(verse.text.cleanVerse)
        if finalReference == nil {
          finalReference = "\(verse.book_name) \(verse.chapter):"
        }
      } else {
        debugLog("DEBUG: Could not find verse \(verseNumber) for reference: \(reference)")
        return nil
      }
    }

    guard let refPrefix = finalReference else {
      debugLog("DEBUG: Failed to build reference prefix for \(reference)")
      return nil
    }

    let versesText = collectedText.joined(separator: " ")
    let refSuffix = verseRange.lowerBound == verseRange.upperBound
      ? "\(verseRange.lowerBound)"
      : "\(verseRange.lowerBound)-\(verseRange.upperBound)"
    let fullReference = refPrefix + refSuffix
    debugLog("DEBUG: Found verse(s): \(fullReference) - Text: \(versesText.prefix(50))...")
    return (versesText, fullReference)
  }

  // Book name mapping for common variations (kept for compatibility)
  private func normalizeBookName(_ bookName: String) -> String {
    let bookNameMappings: [String: String] = [
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

    return bookNameMappings[bookName] ?? bookName.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
