import SwiftUI

struct AppActivityView: View {
  @EnvironmentObject var activityManager: ReadingActivityManager
  @EnvironmentObject var settings: UserSettings
  @State private var selectedMonth: Int
  @State private var selectedYear: Int
  @State private var refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

  let months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
  ]

  init() {
    let now = Date()
    let calendar = Calendar.current
    _selectedMonth = State(initialValue: calendar.component(.month, from: now))
    _selectedYear = State(initialValue: calendar.component(.year, from: now))
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Header
        VStack(spacing: 8) {
          Text("Reading Activity")
            .font(.title2)
            .bold()

          Text("Track your daily reading journey")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.top)

        // Year Overview - Fixed alignment and formatting
        VStack(spacing: 16) {
          VStack(spacing: 16) {
            HStack {
              Text("\(String(selectedYear)) Overview")
                .font(.headline)
              Spacer()
              Text("\(totalDaysRead) days read")
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)  // Added padding to align with cards

            HStack(spacing: 16) {
              StatCard(
                title: "Today's Time",
                value: formatTimeShort(activityManager.todayTimeSpent),
                subtitle: "spent reading",
                color: .indigo
              )

              StatCard(
                title: "Total Time",
                value: formatTimeShort(activityManager.getTotalTimeSpent()),
                subtitle: "all time",
                color: .mint
              )
            }
            .padding(.horizontal)
          }
        }

        // Month Selector
        ScrollViewReader { proxy in
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              ForEach(1...12, id: \.self) { month in
                MonthButton(
                  month: month,
                  monthName: months[month - 1],
                  isSelected: month == selectedMonth,
                  hasActivity: monthHasActivity(month)
                ) {
                  withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    selectedMonth = month
                  }
                }
                .id(month)
              }
            }
            .padding(.horizontal)
          }
          .onAppear {
            // Scroll to current month when view appears
            proxy.scrollTo(selectedMonth, anchor: .center)
          }
        }

        // Calendar View
        VStack(spacing: 16) {
          // Weekday headers
          HStack(spacing: 0) {
            ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
              Text(day)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity)
            }
          }
          .padding(.horizontal)

          // Calendar Grid
          CalendarGrid(
            month: selectedMonth,
            year: selectedYear,
            readingDates: activityManager.readingDates
          )
          .padding(.horizontal)
        }
        .padding()
        .background(
          RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)

        // Statistics
        VStack(spacing: 16) {
          Text("Statistics")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)

          HStack(spacing: 16) {
            StatCard(
              title: "Current Streak",
              value: "\(currentStreak)",
              subtitle: "days",
              color: .orange
            )

            StatCard(
              title: "Longest Streak",
              value: "\(longestStreak)",
              subtitle: "days",
              color: .purple
            )
          }

          HStack(spacing: 16) {
            StatCard(
              title: "This Month",
              value: "\(daysReadThisMonth)",
              subtitle: formatTime(monthTimeSpent),
              color: .blue
            )

            StatCard(
              title: "Consistency",
              value: "\(Int(consistencyRate * 100))%",
              subtitle: "this year",
              color: .green
            )
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 40)
      }
    }
    .scrollDisabled(false)
    .scrollBounceBehavior(.basedOnSize)
    .background(Color(.systemGroupedBackground))
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .onReceive(refreshTimer) { _ in
      // Force view update to show current time
      activityManager.updateTodayTimeSpent()
    }
  }

  // MARK: - Helper Properties

  var monthTimeSpent: TimeInterval {
    activityManager.getTimeSpentThisMonth(month: selectedMonth, year: selectedYear)
  }

  func formatTime(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) % 3600 / 60

    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes) minutes"
    }
  }

  func formatTimeShort(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) % 3600 / 60

    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }

  var totalDaysRead: Int {
    let calendar = Calendar.current
    return activityManager.readingDates.filter {
      calendar.component(.year, from: $0) == selectedYear
    }.count
  }

  var yearProgress: Double {
    let daysInYear = Calendar.current.range(of: .day, in: .year, for: Date())?.count ?? 365
    return Double(totalDaysRead) / Double(daysInYear)
  }

  var daysReadThisMonth: Int {
    let calendar = Calendar.current
    return activityManager.readingDates.filter {
      calendar.component(.year, from: $0) == selectedYear
        && calendar.component(.month, from: $0) == selectedMonth
    }.count
  }

  var currentStreak: Int {
    let calendar = Calendar.current
    let today = Date()
    var streak = 0
    var checkDate = today

    while activityManager.readingDates.contains(where: {
      calendar.isDate($0, inSameDayAs: checkDate)
    }) {
      streak += 1
      guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
      checkDate = previousDay
    }

    return streak
  }

  var longestStreak: Int {
    // Simple implementation - can be optimized
    let sortedDates = activityManager.readingDates.sorted()
    var longest = 0
    var current = 0
    var previousDate: Date?

    for date in sortedDates {
      if let prev = previousDate,
        Calendar.current.dateComponents([.day], from: prev, to: date).day == 1
      {
        current += 1
      } else {
        current = 1
      }
      longest = max(longest, current)
      previousDate = date
    }

    return longest
  }

  var consistencyRate: Double {
    let calendar = Calendar.current
    let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: Date()))!
    let daysSinceStart = calendar.dateComponents([.day], from: startOfYear, to: Date()).day ?? 1
    return Double(totalDaysRead) / Double(max(daysSinceStart, 1))
  }

  func monthHasActivity(_ month: Int) -> Bool {
    let calendar = Calendar.current
    return activityManager.readingDates.contains {
      calendar.component(.year, from: $0) == selectedYear
        && calendar.component(.month, from: $0) == month
    }
  }
}

struct MonthButton: View {
  let month: Int
  let monthName: String
  let isSelected: Bool
  let hasActivity: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 4) {
        Text(String(monthName.prefix(3)))
          .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
          .foregroundColor(isSelected ? .white : .primary)

        if hasActivity {
          Circle()
            .fill(isSelected ? Color.white : Color.green)
            .frame(width: 4, height: 4)
        }
      }
      .frame(width: 50, height: 50)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(isSelected ? Color.blue : Color(.systemGray6))
      )
    }
  }
}

struct CalendarGrid: View {
  let month: Int
  let year: Int
  let readingDates: [Date]
  @EnvironmentObject var activityManager: ReadingActivityManager
  @State private var selectedDate: Date?

  var daysInMonth: [Date] {
    let calendar = Calendar.current
    guard let monthStart = calendar.date(from: DateComponents(year: year, month: month)),
      let range = calendar.range(of: .day, in: .month, for: monthStart)
    else { return [] }

    return range.compactMap { day -> Date? in
      calendar.date(from: DateComponents(year: year, month: month, day: day))
    }
  }

  var firstWeekday: Int {
    let calendar = Calendar.current
    guard let firstDay = daysInMonth.first else { return 1 }
    return calendar.component(.weekday, from: firstDay)
  }

  let columns = Array(repeating: GridItem(.flexible()), count: 7)

  var body: some View {
    LazyVGrid(columns: columns, spacing: 10) {
      // Fill blank cells until the first day
      ForEach(0..<(firstWeekday - 1), id: \.self) { _ in
        Text("")
          .frame(width: 35, height: 35)
      }

      // Calendar days
      ForEach(daysInMonth, id: \.self) { date in
        let day = Calendar.current.component(.day, from: date)
        let isRead = isReading(date)
        let isToday = Calendar.current.isDateInToday(date)
        let timeSpent = activityManager.getTimeSpent(for: date)

        Button(action: {
          selectedDate = selectedDate == date ? nil : date
        }) {
          VStack(spacing: 2) {
            ZStack {
              Circle()
                .fill(isRead ? Color.green : Color.gray.opacity(0.1))
                .frame(width: 35, height: 35)

              if isToday {
                Circle()
                  .stroke(Color.blue, lineWidth: 2)
                  .frame(width: 35, height: 35)
              }

              Text("\(day)")
                .font(.system(size: 14, weight: isToday ? .semibold : .regular))
                .foregroundColor(isRead ? .white : .primary)
            }

            if timeSpent > 0 && selectedDate == date {
              Text(formatTimeCompact(timeSpent))
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            }
          }
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
  }

  func isReading(_ date: Date) -> Bool {
    let calendar = Calendar.current
    return readingDates.contains { calendar.isDate($0, inSameDayAs: date) }
  }

  func formatTimeCompact(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    if minutes >= 60 {
      let hours = minutes / 60
      return "\(hours)h"
    }
    return "\(minutes)m"
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let subtitle: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)

      HStack(alignment: .lastTextBaseline, spacing: 4) {
        Text(value)
          .font(.system(size: 28, weight: .bold))
          .foregroundColor(color)
          .lineLimit(1)
          .minimumScaleFactor(0.8)

        Text(subtitle)
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(2)
      }
    }
    .frame(maxWidth: .infinity, minHeight: 80, alignment: .leading)
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(Color(.secondarySystemGroupedBackground))
    )
  }
}

struct AppActivityView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      AppActivityView()
        .environmentObject(ReadingActivityManager())
        .environmentObject(UserSettings())
    }
  }
}
