// Prayer.swift
import Foundation

struct Prayer: Identifiable, Codable {
  let id: UUID
  let title: String?
  let content: String
  let date: Date

  init(title: String? = nil, content: String) {
    self.id = UUID()
    self.title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.content = content
    self.date = Date()
  }

  // Initialize with existing ID and date (for editing)
  init(id: UUID, title: String? = nil, content: String, date: Date) {
    self.id = id
    self.title = title?.trimmingCharacters(in: .whitespacesAndNewlines)
    self.content = content
    self.date = date
  }

  // Custom coding keys for proper encoding/decoding
  enum CodingKeys: String, CodingKey {
    case id, title, content, date
  }
}
