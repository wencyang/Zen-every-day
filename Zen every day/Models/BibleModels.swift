import Foundation

struct Bible: Codable {
  let metadata: Metadata
  let verses: [Verse]
}

struct Metadata: Codable {
  let name: String
  let shortname: String
  let description: String
}

struct Verse: Codable, Identifiable, Equatable {
  var id: String { "\(book)_\(chapter)_\(verse)" }
  let book_name: String
  let book: Int
  let chapter: Int
  let verse: Int
  let text: String

  // MARK: - Equatable Conformance
  static func == (lhs: Verse, rhs: Verse) -> Bool {
    return lhs.book_name == rhs.book_name && lhs.chapter == rhs.chapter && lhs.verse == rhs.verse
  }
}
