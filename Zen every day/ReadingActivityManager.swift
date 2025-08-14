import Foundation
import SwiftUI

struct DailyActivity: Codable {
  let date: String  // Format: "yyyy-MM-dd"
  var timeSpent: TimeInterval  // In seconds
}

class ReadingActivityManager: ObservableObject {
  @Published var readingDates: [Date] = []
  @Published var dailyActivities: [DailyActivity] = []
  @Published var sessionStartTime: Date?
  @Published var todayTimeSpent: TimeInterval = 0

  private let readingDatesKey = "readingDates"
  private let dailyActivitiesKey = "dailyActivities"
  private var timer: Timer?

  init() {
    loadDates()
    loadDailyActivities()
    markTodayAsRead()
    startSession()

    // Update today's time spent
    updateTodayTimeSpent()

    // Set up timer to update time spent every minute
    timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
      self.saveCurrentSession()
      self.updateTodayTimeSpent()
    }
  }

  deinit {
    endSession()
    timer?.invalidate()
  }

  func loadDates() {
    if let stored = UserDefaults.standard.array(forKey: readingDatesKey) as? [String] {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-dd"
      let dates = stored.compactMap { formatter.date(from: $0) }
      self.readingDates = dates
    }
  }

  func loadDailyActivities() {
    if let data = UserDefaults.standard.data(forKey: dailyActivitiesKey),
      let activities = try? JSONDecoder().decode([DailyActivity].self, from: data)
    {
      self.dailyActivities = activities
    }
  }

  func markTodayAsRead() {
    let today = Date()
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: today)

    // Check if today's date is already recorded
    if !readingDates.contains(where: { formatter.string(from: $0) == todayString }) {
      readingDates.append(today)
      saveDates()
    }
  }

  func saveDates() {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let strings = readingDates.map { formatter.string(from: $0) }
    UserDefaults.standard.set(strings, forKey: readingDatesKey)
  }

  func saveDailyActivities() {
    if let data = try? JSONEncoder().encode(dailyActivities) {
      UserDefaults.standard.set(data, forKey: dailyActivitiesKey)
    }
  }

  // MARK: - Session Management

  func startSession() {
    sessionStartTime = Date()
  }

  func endSession() {
    saveCurrentSession()
    sessionStartTime = nil
  }

  func saveCurrentSession() {
    guard let startTime = sessionStartTime else { return }

    let timeSpent = Date().timeIntervalSince(startTime)
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())

    // Find or create today's activity
    if let index = dailyActivities.firstIndex(where: { $0.date == todayString }) {
      dailyActivities[index].timeSpent += timeSpent
    } else {
      let newActivity = DailyActivity(date: todayString, timeSpent: timeSpent)
      dailyActivities.append(newActivity)
    }

    saveDailyActivities()

    // Reset session start time
    sessionStartTime = Date()
  }

  func updateTodayTimeSpent() {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let todayString = formatter.string(from: Date())

    if let activity = dailyActivities.first(where: { $0.date == todayString }) {
      todayTimeSpent = activity.timeSpent
    } else {
      todayTimeSpent = 0
    }

    // Add current session time if active
    if let startTime = sessionStartTime {
      todayTimeSpent += Date().timeIntervalSince(startTime)
    }
  }

  // MARK: - Helper Methods

  func getTimeSpent(for date: Date) -> TimeInterval {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    let dateString = formatter.string(from: date)

    if let activity = dailyActivities.first(where: { $0.date == dateString }) {
      return activity.timeSpent
    }
    return 0
  }

  func getTotalTimeSpent() -> TimeInterval {
    return dailyActivities.reduce(0) { $0 + $1.timeSpent }
  }

  func getTimeSpentThisMonth(month: Int, year: Int) -> TimeInterval {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    return dailyActivities.filter { activity in
      if let date = formatter.date(from: activity.date) {
        let calendar = Calendar.current
        return calendar.component(.month, from: date) == month
          && calendar.component(.year, from: date) == year
      }
      return false
    }.reduce(0) { $0 + $1.timeSpent }
  }

  func getTimeSpentThisYear(year: Int) -> TimeInterval {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"

    return dailyActivities.filter { activity in
      if let date = formatter.date(from: activity.date) {
        let calendar = Calendar.current
        return calendar.component(.year, from: date) == year
      }
      return false
    }.reduce(0) { $0 + $1.timeSpent }
  }

  // App lifecycle methods
  func appDidBecomeActive() {
    startSession()
  }

  func appWillResignActive() {
    endSession()
  }
}
