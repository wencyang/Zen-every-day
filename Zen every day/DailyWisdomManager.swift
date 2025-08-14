import Combine
import SwiftUI

class DailyWisdomManager: ObservableObject {
    @Published var dailyQuote: WisdomQuote?
    @Published var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    init() {
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
        dailyQuote = quotes[index]
    }

    private func stableHash(_ s: String) -> Int {
        return s.unicodeScalars.map { Int($0.value) }.reduce(0, +)
    }
}
