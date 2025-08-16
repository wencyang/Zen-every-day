import Combine
import SwiftUI

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

  init() {
    loadSavedQuotes()
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
        let photoName = UserDefaults.standard.string(forKey: "backgroundPhotoName")
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

    let photoName = UserDefaults.standard.string(forKey: "backgroundPhotoName")
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

  private func persistSavedQuotes() {
    if let encoded = try? JSONEncoder().encode(savedQuotes) {
      UserDefaults.standard.set(encoded, forKey: savedQuotesKey)
    }
  }
}

