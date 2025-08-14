import Combine
import SwiftUI

struct WisdomQuote: Codable, Identifiable, Equatable {
    let id: String
    let author: String?
    let text: String
    let work: String?
    let ref: String?
    let language: String?
    let license: String?
    let source: String?
    let tags: [String]?
}

class WisdomManager: ObservableObject {
    static let shared = WisdomManager()

    @Published var quotes: [WisdomQuote] = []
    @Published var isLoaded = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    func loadWisdomIfNeeded() {
        guard !isLoaded && !isLoading else { return }
        isLoading = true

        guard let dataAsset = NSDataAsset(name: "buddhist_wisdom_cc0") else {
            self.errorMessage = "Could not load buddhist_wisdom_cc0 asset."
            self.isLoading = false
            return
        }

        do {
            let loadedQuotes = try JSONDecoder().decode([WisdomQuote].self, from: dataAsset.data)
            self.quotes = loadedQuotes
            self.isLoaded = true
            self.isLoading = false
        } catch {
            self.errorMessage = "Failed to decode wisdom: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}
