//
//  Extensions.swift
//  Zen Every Day
//
//  Simple extension to remove the ¶ character
//

import Foundation

extension String {
  var cleanVerse: String {
    return self.replacingOccurrences(of: "\u{00b6}", with: "")
  }

  /// Removes any parenthetical "paraphrase" notes for cleaner display
  var removingParaphrase: String {
    return self.replacingOccurrences(
      of: "\\s*\\(.*?paraphrase.*?\\)",
      with: "",
      options: [.regularExpression, .caseInsensitive]
    ).trimmingCharacters(in: .whitespacesAndNewlines)
  }
}
