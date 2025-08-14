import Combine
// PrayerManager.swift
import Foundation

class PrayerManager: ObservableObject {
  @Published var prayers: [Prayer] = []

  private let storageKey = "userPrayers"

  init() {
    load()
  }

  func addPrayer(_ prayer: Prayer) {
    prayers.append(prayer)
    save()
  }

  func updatePrayer(_ updatedPrayer: Prayer) {
    if let index = prayers.firstIndex(where: { $0.id == updatedPrayer.id }) {
      prayers[index] = updatedPrayer
      save()
      debugLog("DEBUG: Updated prayer at index \(index) with ID: \(updatedPrayer.id)")
    } else {
      debugLog("DEBUG: Could not find prayer with ID: \(updatedPrayer.id)")
    }
  }

  func deletePrayer(_ prayer: Prayer) {
    prayers.removeAll { $0.id == prayer.id }
    save()
  }

  private func save() {
    if let data = try? JSONEncoder().encode(prayers) {
      UserDefaults.standard.set(data, forKey: storageKey)
    }
  }

  private func load() {
    if let data = UserDefaults.standard.data(forKey: storageKey),
      let decoded = try? JSONDecoder().decode([Prayer].self, from: data)
    {
      prayers = decoded
    }
  }
}
