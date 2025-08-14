import Foundation

struct DailyVerseEntry: Identifiable, Codable {
    let date: String
    let reference: String
    let text: String

    var id: String { "\(date)_\(reference)" }
}

