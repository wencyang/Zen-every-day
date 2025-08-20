import Foundation

struct DailyQuoteEntry: Identifiable, Codable {
    let date: String
    let author: String?
    let text: String
    /// Stores the original wisdom quote identifier so that the
    /// same quote appearing on different days can be recognized.
    let quoteId: String?
    /// Name of the background image used when the quote was shown.
    let backgroundPhotoName: String?

    /// Use the date as the identifier for displaying history entries.
    var id: String { date }
}

