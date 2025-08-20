import Combine
import SwiftUI
import UIKit

class DailyWisdomManager: ObservableObject {
    @Published var dailyQuote: WisdomQuote?
    @Published var errorMessage: String?
    /// Name of the background image associated with today's quote.
    @Published var backgroundPhotoName: String?

    private var cancellables = Set<AnyCancellable>()
    private let photoNames: [String]

    init() {
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
        self.photoNames = names.isEmpty ? ["photo1"] : names

        WisdomManager.shared.loadWisdomIfNeeded()
        WisdomManager.shared.$isLoaded
            .filter { $0 }
            .sink { [weak self] _ in
                self?.setDailyQuote()
            }
            .store(in: &cancellables)

        if WisdomManager.shared.isLoaded {
            setDailyQuote()
        }
    }

    private func setDailyQuote() {
        let quotes = WisdomManager.shared.quotes
        guard !quotes.isEmpty else {
            errorMessage = "Wisdom not available"
            return
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayString = formatter.string(from: Date())
        let index = stableHash(todayString) % quotes.count
        let quote = quotes[index]
        dailyQuote = quote
        backgroundPhotoName = photoNames.randomElement()
        saveToHistory(quote)
    }

    private func stableHash(_ s: String) -> Int {
        return s.unicodeScalars.map { Int($0.value) }.reduce(0, +)
    }

    private func saveToHistory(_ quote: WisdomQuote) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())

        var history: [DailyQuoteEntry] = []
        if let data = UserDefaults.standard.data(forKey: "dailyQuoteHistory"),
           let decoded = try? JSONDecoder().decode([DailyQuoteEntry].self, from: data) {
            history = decoded
        }

        if !history.contains(where: { $0.date == today }) {
            let entry = DailyQuoteEntry(
                date: today,
                author: quote.author,
                text: quote.text,
                quoteId: quote.id,
                backgroundPhotoName: backgroundPhotoName
            )
            history.append(entry)
            if history.count > 30 { history = Array(history.suffix(30)) }
            if let encoded = try? JSONEncoder().encode(history) {
                UserDefaults.standard.set(encoded, forKey: "dailyQuoteHistory")
            }
        }
    }
}
