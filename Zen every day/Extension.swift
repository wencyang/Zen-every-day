//
//  Extensions.swift
//  Daily Bible
//
//  Simple extension to remove the ¶ character
//

import Foundation

extension String {
  var cleanVerse: String {
    return self.replacingOccurrences(of: "\u{00b6}", with: "")
  }
}
