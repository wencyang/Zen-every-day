import Combine
import SwiftUI
import UIKit

struct SavedQuote: Codable, Identifiable {
  let id: String
  let author: String?
  let text: String
  let work: String?
  let dateSaved: Date
  let backgroundPhotoName: String?
}

class SavedQuotesManager: ObservableObject {
  @Published var savedQuotes: [SavedQuote] = []
  @Published var showSavedToast = false
  @Published var showRemovedToast = false

  private let savedQuotesKey = "savedQuotes"
  private var savedIDs: Set<String> = []
  
  // Reference to DailyWisdomManager to get current background
  private weak var dailyWisdomManager: DailyWisdomManager?

  init(dailyWisdomManager: DailyWisdomManager? = nil) {
    self.dailyWisdomManager = dailyWisdomManager
    loadSavedQuotes()
    
    // Debug: Print what we have
    print("=== SavedQuotesManager Debug ===")
    print("Loaded \(savedQuotes.count) saved quotes")
    for quote in savedQuotes {
      print("Quote: \(quote.text.prefix(50))... | Background: \(quote.backgroundPhotoName ?? "nil")")
    }
  }
  
  // Method to set the daily wisdom manager reference
  func setDailyWisdomManager(_ manager: DailyWisdomManager) {
    self.dailyWisdomManager = manager
  }

  private func loadSavedQuotes() {
    if let data = UserDefaults.standard.data(forKey: savedQuotesKey),
       let decoded = try? JSONDecoder().decode([SavedQuote].self, from: data) {
      // Remove any duplicate entries that might have been saved
      // before the duplicate check was added. This also merges
      // entries that used the quote text as their identifier.
      var uniqueQuotes: [String: SavedQuote] = [:]
      for quote in decoded {
        let key = "\(quote.text)|\(quote.author ?? "")"
        if let existing = uniqueQuotes[key] {
          // Prefer the entry that has a proper id (not just the text)
          if existing.id == existing.text && quote.id != quote.text {
            uniqueQuotes[key] = quote
          }
        } else {
          uniqueQuotes[key] = quote
        }
      }

      savedQuotes = Array(uniqueQuotes.values)
      savedIDs = Set(savedQuotes.map { $0.id })

      // Persist cleaned list if duplicates were removed
      if uniqueQuotes.count != decoded.count {
        persistSavedQuotes()
      }
    }
  }

  func saveQuote(_ quote: WisdomQuote) {
    // If a quote with the same text and author already exists but
    // uses a different identifier (older versions stored the text as
    // the identifier), update it instead of creating a duplicate.
    if let index = savedQuotes.firstIndex(where: { $0.text == quote.text && $0.author == quote.author }) {
      if savedQuotes[index].id != quote.id {
        savedIDs.remove(savedQuotes[index].id)
        let photoName = getCurrentBackgroundPhotoName()
        print("Updating existing quote with background: \(photoName ?? "nil")")
        savedQuotes[index] = SavedQuote(
          id: quote.id,
          author: quote.author,
          text: quote.text,
          work: quote.work,
          dateSaved: savedQuotes[index].dateSaved,
          backgroundPhotoName: photoName
        )
        savedIDs.insert(quote.id)
        persistSavedQuotes()
      }
      return
    }

    guard !savedIDs.contains(quote.id) else { return }

    let photoName = getCurrentBackgroundPhotoName()
    print("Saving new quote with background: \(photoName ?? "nil")")
    
    let savedQuote = SavedQuote(
      id: quote.id,
      author: quote.author,
      text: quote.text,
      work: quote.work,
      dateSaved: Date(),
      backgroundPhotoName: photoName
    )

    savedQuotes.append(savedQuote)
    savedIDs.insert(savedQuote.id)

    DispatchQueue.main.async {
      let impactFeedback = UIImpactFeedbackGenerator(style: .light)
      impactFeedback.impactOccurred()

      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        self.showSavedToast = true
      }
    }

    persistSavedQuotes()
  }

  func removeQuote(_ quote: WisdomQuote) {
    guard isQuoteSaved(quote) else { return }

    let removed = savedQuotes.filter { $0.id == quote.id || ($0.text == quote.text && $0.author == quote.author) }
    savedQuotes.removeAll { $0.id == quote.id || ($0.text == quote.text && $0.author == quote.author) }
    removed.forEach { savedIDs.remove($0.id) }

    DispatchQueue.main.async {
      let impactFeedback = UIImpactFeedbackGenerator(style: .light)
      impactFeedback.impactOccurred()

      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        self.showRemovedToast = true
      }
    }

    persistSavedQuotes()
  }

  func removeSavedQuote(_ savedQuote: SavedQuote) {
    savedQuotes.removeAll { $0.id == savedQuote.id }
    savedIDs.remove(savedQuote.id)
    DispatchQueue.main.async {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
        self.showRemovedToast = true
      }
    }
    persistSavedQuotes()
  }

  func copySavedQuote(_ savedQuote: SavedQuote) {
    var copyText = savedQuote.text
    if let author = savedQuote.author {
      copyText += "\n- \(author)"
    }
    UIPasteboard.general.string = copyText
  }

  func isQuoteSaved(_ quote: WisdomQuote) -> Bool {
    if savedIDs.contains(quote.id) {
      return true
    }
    // Fallback to text/author match for quotes saved by older app versions
    return savedQuotes.contains { $0.text == quote.text && $0.author == quote.author }
  }

  func toggleQuoteSaved(_ quote: WisdomQuote) {
    if isQuoteSaved(quote) {
      removeQuote(quote)
    } else {
      saveQuote(quote)
    }
  }

  func updateMissingBackgrounds() {
    var updated = false
    for i in 0..<savedQuotes.count {
      if savedQuotes[i].backgroundPhotoName == nil || savedQuotes[i].backgroundPhotoName?.isEmpty == true {
        let newBackground = generateRandomPhotoName()
        savedQuotes[i] = SavedQuote(
          id: savedQuotes[i].id,
          author: savedQuotes[i].author,
          text: savedQuotes[i].text,
          work: savedQuotes[i].work,
          dateSaved: savedQuotes[i].dateSaved,
          backgroundPhotoName: newBackground
        )
        updated = true
      }
    }
    if updated {
      persistSavedQuotes()
    }
  }

  private func persistSavedQuotes() {
    if let encoded = try? JSONEncoder().encode(savedQuotes) {
      UserDefaults.standard.set(encoded, forKey: savedQuotesKey)
    }
  }
  
  // Get the current background photo name from DailyWisdomManager
  private func getCurrentBackgroundPhotoName() -> String? {
    if let manager = dailyWisdomManager, let backgroundName = manager.backgroundPhotoName {
      print("Got background from DailyWisdomManager: \(backgroundName)")
      return backgroundName
    }
    
    // Fallback: Generate a random photo name using the same logic as DailyWisdomManager
    var names: [String] = []
    var index = 1
    while index <= 1000 {
      let name = "photo\(index)"
      if UIImage(named: name) != nil || NSDataAsset(name: name) != nil {
        names.append(name)
        index += 1
      } else {
        break
      }
    }
    let photoNames = names.isEmpty ? ["photo1"] : names
    let randomName = photoNames.randomElement() ?? "photo1"
    print("Using fallback random background: \(randomName)")
    return randomName
  }

  private func generateRandomPhotoName() -> String {
    var names: [String] = []
    var index = 1
    while index <= 1000 {
      let name = "photo\(index)"
      if UIImage(named: name) != nil || NSDataAsset(name: name) != nil {
        names.append(name)
        index += 1
      } else {
        break
      }
    }
    let photoNames = names.isEmpty ? ["photo1"] : names
    return photoNames.randomElement() ?? "photo1"
  }
}
