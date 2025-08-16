import Foundation

struct DailyQuoteEntry: Identifiable, Codable {
    let date: String
    let author: String?
    let text: String

    var id: String { "\(date)_\(text)" }
}

