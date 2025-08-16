import Combine
import SwiftUI

struct SavedQuote: Codable, Identifiable {
  let id: String
  let author: String?
  let text: String
  let work: String?
  let dateSaved: Date
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
      savedQuotes = decoded
      savedIDs = Set(decoded.map { $0.id })
    }
  }

  func saveQuote(_ quote: WisdomQuote) {
    guard !isQuoteSaved(quote) else { return }

    let savedQuote = SavedQuote(
      id: quote.id,
      author: quote.author,
      text: quote.text,
      work: quote.work,
      dateSaved: Date()
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

    savedQuotes.removeAll { $0.id == quote.id }
    savedIDs.remove(quote.id)

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
    savedIDs.contains(quote.id)
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

