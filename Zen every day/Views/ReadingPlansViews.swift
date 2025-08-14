// MARK: - Reading Plan Models
import Foundation
import SwiftUI

struct ReadingPlan: Codable, Identifiable {
  let id: String
  let title: String
  let description: String
  let duration: Int  // days
  let category: PlanCategory
  let icon: String
  let color: PlanColor
  var readings: [DailyReading]  // Changed to var

  var isCompleted: Bool {
    readings.allSatisfy { $0.isCompleted }
  }

  var completedDays: Int {
    readings.filter { $0.isCompleted }.count
  }

  var progressPercentage: Double {
    guard !readings.isEmpty else { return 0 }
    return Double(completedDays) / Double(readings.count)
  }
}

struct DailyReading: Codable, Identifiable {
  let id: String
  let day: Int
  let title: String
  let references: [VerseReference]
  var isCompleted: Bool = false
  var completedDate: Date?
}

struct VerseReference: Codable, Identifiable {
  let id: UUID
  let bookName: String
  let chapter: Int
  let startVerse: Int
  let endVerse: Int

  init(bookName: String, chapter: Int, startVerse: Int, endVerse: Int) {
    self.id = UUID()
    self.bookName = bookName
    self.chapter = chapter
    self.startVerse = startVerse
    self.endVerse = endVerse
  }

  var displayText: String {
    if startVerse == endVerse {
      return "\(bookName) \(chapter):\(startVerse)"
    } else {
      return "\(bookName) \(chapter):\(startVerse)-\(endVerse)"
    }
  }

  var shortDisplayText: String {
    if startVerse == endVerse {
      return "\(bookName) \(chapter):\(startVerse)"
    } else {
      return "\(bookName) \(chapter):\(startVerse)-\(endVerse)"
    }
  }
}

enum PlanCategory: String, Codable, CaseIterable {
  case beginner = "Beginner"
  case topical = "Topical"
  case character = "Character Study"
  case seasonal = "Seasonal"
  case complete = "Complete Reading"

  var icon: String {
    switch self {
    case .beginner: return "book.fill"
    case .topical: return "heart.fill"
    case .character: return "person.fill"
    case .seasonal: return "calendar"
    case .complete: return "books.vertical.fill"
    }
  }
}

enum PlanColor: String, Codable, CaseIterable {
  case blue, purple, green, orange, red, teal, indigo, pink

  var color: Color {
    switch self {
    case .blue: return .blue
    case .purple: return .purple
    case .green: return .green
    case .orange: return .orange
    case .red: return .red
    case .teal: return .teal
    case .indigo: return .indigo
    case .pink: return .pink
    }
  }
}

// MARK: - Reading Plans Manager
class ReadingPlansManager: ObservableObject {
  @Published var availablePlans: [ReadingPlan] = []
  @Published var activePlans: [ReadingPlan] = []
  @Published var isLoading = false

  private let activePlansKey = "activeReadingPlans"

  init() {
    loadAvailablePlans()
    loadActivePlans()
  }

  // MARK: - Plan Management
  func startPlan(_ plan: ReadingPlan) {
    var newPlan = plan
    // Reset all readings to incomplete
    newPlan.readings = plan.readings.map { reading in
      var updatedReading = reading
      updatedReading.isCompleted = false
      updatedReading.completedDate = nil
      return updatedReading
    }

    activePlans.append(newPlan)
    saveActivePlans()
  }

  func isDayActuallyCompleted(planId: String, day: Int) -> Bool {
    // Check if all verses for this day are marked as completed
    let key = "completed_verses_\(planId)_\(day)"
    if let completedVerseIds = UserDefaults.standard.array(forKey: key) as? [String],
       !completedVerseIds.isEmpty {
      // Get the reading for this day to check total verses
      if let plan = activePlans.first(where: { $0.id == planId }),
         let reading = plan.readings.first(where: { $0.day == day }) {
        // Estimate total verses from references
        let estimatedTotal = reading.references.reduce(0) { total, ref in
          total + (ref.endVerse - ref.startVerse + 1)
        }
        // Day is complete if completed verses >= estimated total
        return completedVerseIds.count >= estimatedTotal
      }
    }
    return false
  }

  func getActualCompletedDays(for planId: String) -> Int {
    guard let plan = activePlans.first(where: { $0.id == planId }) else { return 0 }
    
    var completedCount = 0
    for reading in plan.readings {
      if isDayActuallyCompleted(planId: planId, day: reading.day) {
        completedCount += 1
      }
    }
    return completedCount
  }

  func getActualProgressPercentage(for planId: String) -> Double {
    guard let plan = activePlans.first(where: { $0.id == planId }) else { return 0 }
    let completedDays = getActualCompletedDays(for: planId)
    return Double(completedDays) / Double(plan.readings.count)
  }

  func markDayCompleted(planId: String, day: Int) {
    objectWillChange.send()
    if let planIndex = activePlans.firstIndex(where: { $0.id == planId }),
      let readingIndex = activePlans[planIndex].readings.firstIndex(where: { $0.day == day })
    {
      activePlans[planIndex].readings[readingIndex].isCompleted = true
      activePlans[planIndex].readings[readingIndex].completedDate = Date()
      saveActivePlans()
    }
  }

  func markDayIncomplete(planId: String, day: Int) {
    objectWillChange.send()
    if let planIndex = activePlans.firstIndex(where: { $0.id == planId }),
      let readingIndex = activePlans[planIndex].readings.firstIndex(where: { $0.day == day })
    {
      activePlans[planIndex].readings[readingIndex].isCompleted = false
      activePlans[planIndex].readings[readingIndex].completedDate = nil
      saveActivePlans()
    }
  }

  func getNextUnreadDay(for planId: String) -> DailyReading? {
    guard let plan = activePlans.first(where: { $0.id == planId }) else { return nil }
    
    // Find the first day that isn't actually completed
    for reading in plan.readings {
      if !isDayActuallyCompleted(planId: planId, day: reading.day) {
        return reading
      }
    }
    
    return nil
  }

  func removePlan(_ planId: String) {
    activePlans.removeAll { $0.id == planId }
    saveActivePlans()
  }

  // MARK: - Data Loading
  private func loadAvailablePlans() {
    availablePlans = createDefaultPlans()
  }

  private func loadActivePlans() {
    if let data = UserDefaults.standard.data(forKey: activePlansKey),
      let plans = try? JSONDecoder().decode([ReadingPlan].self, from: data)
    {
      activePlans = plans
    }
  }

  private func saveActivePlans() {
    if let data = try? JSONEncoder().encode(activePlans) {
      UserDefaults.standard.set(data, forKey: activePlansKey)
    }
  }

  // MARK: - Default Plans Creation
  private func createDefaultPlans() -> [ReadingPlan] {
    return [
      // Life of Jesus Plan
      ReadingPlan(
        id: "life-of-jesus",
        title: "Life of Jesus",
        description: "Journey through the life and teachings of Christ in 40 days",
        duration: 40,
        category: .character,
        icon: "cross.fill",
        color: .blue,
        readings: createLifeOfJesusReadings()
      ),

      // Psalms & Proverbs
      ReadingPlan(
        id: "psalms-proverbs",
        title: "Psalms & Proverbs",
        description: "Wisdom and worship through Psalms and Proverbs in 31 days",
        duration: 31,
        category: .topical,
        icon: "music.note",
        color: .purple,
        readings: createPsalmsProverbsReadings()
      ),

      // Faith Builders
      ReadingPlan(
        id: "faith-builders",
        title: "Faith Builders",
        description: "Strengthen your faith with powerful verses over 21 days",
        duration: 21,
        category: .topical,
        icon: "heart.fill",
        color: .red,
        readings: createFaithBuildersReadings()
      ),

      // Comfort & Hope
      ReadingPlan(
        id: "comfort-hope",
        title: "Comfort & Hope",
        description: "Find peace and encouragement in difficult times",
        duration: 14,
        category: .topical,
        icon: "heart.text.square.fill",
        color: .teal,
        readings: createComfortHopeReadings()
      ),

      // Genesis Foundations
      ReadingPlan(
        id: "genesis-foundations",
        title: "Genesis Foundations",
        description: "Explore the beginnings of God's story in 10 days",
        duration: 10,
        category: .beginner,
        icon: "leaf.fill",
        color: .green,
        readings: createGenesisFoundationsReadings()
      ),

      // Parables of Jesus
      ReadingPlan(
        id: "parables-of-jesus",
        title: "Parables of Jesus",
        description: "Discover Christ's teaching through 14 parables",
        duration: 14,
        category: .topical,
        icon: "quote.bubble.fill",
        color: .orange,
        readings: createParablesOfJesusReadings()
      ),

      // Armor of God
      ReadingPlan(
        id: "armor-of-god",
        title: "Armor of God",
        description: "Study Ephesians 6 and stand firm in 7 days",
        duration: 7,
        category: .topical,
        icon: "shield.lefthalf.fill",
        color: .indigo,
        readings: createArmorOfGodReadings()
      ),

      // Jonah Journey
      ReadingPlan(
        id: "jonah-journey",
        title: "Jonah Journey",
        description: "Follow the prophet's flight and redemption in 4 days",
        duration: 4,
        category: .character,
        icon: "fish.fill",
        color: .teal,
        readings: createJonahJourneyReadings()
      ),

      // Ruth's Story
      ReadingPlan(
        id: "ruth-story",
        title: "Ruth's Story",
        description: "Witness loyalty and redemption over 4 days",
        duration: 4,
        category: .character,
        icon: "heart.circle.fill",
        color: .pink,
        readings: createRuthsStoryReadings()
      ),

      // Sermon on the Mount
      ReadingPlan(
        id: "sermon-on-mount",
        title: "Sermon on the Mount",
        description: "Study Jesus' teaching from Matthew 5–7",
        duration: 3,
        category: .topical,
        icon: "mountain.2.fill",
        color: .green,
        readings: createSermonOnTheMountReadings()
      ),

      // Creation Week
      ReadingPlan(
        id: "creation-week",
        title: "Creation Week",
        description: "Experience the 7 days of creation",
        duration: 7,
        category: .beginner,
        icon: "sunrise.fill",
        color: .orange,
        readings: createCreationWeekReadings()
      ),

      // Paul's Prayers
      ReadingPlan(
        id: "paul-prayers",
        title: "Paul's Prayers",
        description: "Reflect on prayers from Paul's letters",
        duration: 7,
        category: .topical,
        icon: "hands.sparkles",
        color: .purple,
        readings: createPaulsPrayersReadings()
      ),

      // Fruit of the Spirit
      ReadingPlan(
        id: "fruit-of-spirit",
        title: "Fruit of the Spirit",
        description: "Cultivate spiritual fruit in 9 days",
        duration: 9,
        category: .topical,
        icon: "leaf.circle.fill",
        color: .orange,
        readings: createFruitOfSpiritReadings()
      ),

      // Ten Commandments
      ReadingPlan(
        id: "ten-commandments",
        title: "Ten Commandments",
        description: "Understand God's law in 10 days",
        duration: 10,
        category: .beginner,
        icon: "list.number",
        color: .blue,
        readings: createTenCommandmentsReadings()
      ),

      // Wisdom from Proverbs
      ReadingPlan(
        id: "proverbs-wisdom",
        title: "Wisdom from Proverbs",
        description: "Highlights from Proverbs over 7 days",
        duration: 7,
        category: .topical,
        icon: "book.fill",
        color: .indigo,
        readings: createProverbsWisdomReadings()
      ),

      // Women of the Bible
      ReadingPlan(
        id: "women-of-faith",
        title: "Women of the Bible",
        description: "Lessons from faithful women in 7 days",
        duration: 7,
        category: .character,
        icon: "person.crop.circle.fill",
        color: .pink,
        readings: createWomenOfFaithReadings()
      ),
    ]
  }

  // MARK: - Reading Plan Data Creation
  private func createLifeOfJesusReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "The Birth of Jesus", [("Luke", 1, 26, 38), ("Luke", 2, 1, 20)]),
      (2, "Jesus in the Temple", [("Luke", 2, 41, 52)]),
      (3, "The Baptism of Jesus", [("Matthew", 3, 13, 17)]),
      (4, "The Temptation", [("Matthew", 4, 1, 11)]),
      (5, "First Disciples", [("Matthew", 4, 18, 22)]),
      (6, "The Beatitudes", [("Matthew", 5, 1, 12)]),
      (7, "Love Your Enemies", [("Matthew", 5, 43, 48)]),
      (8, "The Lord's Prayer", [("Matthew", 6, 5, 15)]),
      (9, "Do Not Worry", [("Matthew", 6, 25, 34)]),
      (10, "Golden Rule", [("Matthew", 7, 7, 12)]),
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "life-jesus-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createPsalmsProverbsReadings() -> [DailyReading] {
    return (1...31).map { day in
      DailyReading(
        id: "psalms-proverbs-\(day)",
        day: day,
        title: "Day \(day): Psalm \(day) & Proverbs \(day)",
        references: [
          VerseReference(bookName: "Psalms", chapter: day, startVerse: 1, endVerse: 50),
          VerseReference(bookName: "Proverbs", chapter: day, startVerse: 1, endVerse: 35),
        ]
      )
    }
  }

  private func createFaithBuildersReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "Faith Defined", [("Hebrews", 11, 1, 6)]),
      (2, "Abraham's Faith", [("Hebrews", 11, 8, 19)]),
      (3, "Faith in Action", [("James", 2, 14, 26)]),
      (4, "Trust in the Lord", [("Proverbs", 3, 5, 8)]),
      (5, "Perfect Peace", [("Isaiah", 26, 3, 4)]),
      (6, "God's Strength", [("Isaiah", 40, 28, 31)]),
      (7, "Never Alone", [("Deuteronomy", 31, 6, 8)]),
      (8, "God's Love", [("Romans", 8, 35, 39)]),
      (9, "Victory in Christ", [("1 Corinthians", 15, 55, 58)]),
      (10, "New Creation", [("2 Corinthians", 5, 17, 21)]),
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "faith-builders-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createComfortHopeReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "God's Comfort", [("2 Corinthians", 1, 3, 7)]),
      (2, "Peace in Trouble", [("John", 16, 33, 33)]),
      (3, "The Lord is Near", [("Philippians", 4, 4, 9)]),
      (4, "Cast Your Cares", [("1 Peter", 5, 6, 7)]),
      (5, "Strength in Weakness", [("2 Corinthians", 12, 7, 10)]),
      (6, "God's Plans", [("Jeremiah", 29, 11, 13)]),
      (7, "Refuge in God", [("Psalms", 46, 1, 11)]),
      (8, "Never Forsaken", [("Psalms", 27, 1, 14)]),
      (9, "Light in Darkness", [("Psalms", 23, 1, 6)]),
      (10, "Hope Anchors", [("Hebrews", 6, 17, 20)]),
      (11, "God's Grace", [("2 Corinthians", 12, 9, 10)]),
      (12, "Eternal Perspective", [("2 Corinthians", 4, 16, 18)]),
      (13, "Future Glory", [("Romans", 8, 18, 25)]),
      (14, "Ultimate Victory", [("1 Corinthians", 15, 54, 57)]),
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "comfort-hope-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createGenesisFoundationsReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "Creation", [("Genesis", 1, 1, 31)]),
      (2, "Garden of Eden", [("Genesis", 2, 4, 25)]),
      (3, "The Fall", [("Genesis", 3, 1, 24)]),
      (4, "Cain and Abel", [("Genesis", 4, 1, 16)]),
      (5, "Noah's Calling", [("Genesis", 6, 9, 22)]),
      (6, "The Flood", [("Genesis", 7, 1, 24)]),
      (7, "God's Covenant", [("Genesis", 9, 8, 17)]),
      (8, "Tower of Babel", [("Genesis", 11, 1, 9)]),
      (9, "Call of Abram", [("Genesis", 12, 1, 9)]),
      (10, "Covenant with Abram", [("Genesis", 15, 1, 6)])
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "genesis-foundations-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createParablesOfJesusReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "The Sower", [("Matthew", 13, 1, 23)]),
      (2, "The Good Samaritan", [("Luke", 10, 25, 37)]),
      (3, "The Prodigal Son", [("Luke", 15, 11, 32)]),
      (4, "The Lost Sheep", [("Luke", 15, 1, 7)]),
      (5, "The Mustard Seed", [("Matthew", 13, 31, 32)]),
      (6, "The Talents", [("Matthew", 25, 14, 30)]),
      (7, "Wise & Foolish Builders", [("Matthew", 7, 24, 27)]),
      (8, "Pharisee & Tax Collector", [("Luke", 18, 9, 14)]),
      (9, "Friend at Midnight", [("Luke", 11, 5, 8)]),
      (10, "The Rich Fool", [("Luke", 12, 13, 21)]),
      (11, "The Ten Virgins", [("Matthew", 25, 1, 13)]),
      (12, "Rich Man & Lazarus", [("Luke", 16, 19, 31)]),
      (13, "The Great Banquet", [("Luke", 14, 15, 24)]),
      (14, "The Unforgiving Servant", [("Matthew", 18, 21, 35)])
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "parables-jesus-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createArmorOfGodReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "Be Strong", [("Ephesians", 6, 10, 13)]),
      (2, "Belt of Truth", [("Ephesians", 6, 14, 14)]),
      (3, "Breastplate of Righteousness", [("Ephesians", 6, 14, 14)]),
      (4, "Gospel of Peace", [("Ephesians", 6, 15, 15)]),
      (5, "Shield of Faith", [("Ephesians", 6, 16, 16)]),
      (6, "Helmet of Salvation", [("Ephesians", 6, 17, 17)]),
      (7, "Prayer & The Sword", [("Ephesians", 6, 17, 20)])
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "armor-god-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createJonahJourneyReadings() -> [DailyReading] {
    let verseCounts = [17, 10, 10, 11]

    return verseCounts.enumerated().map { index, count in
      let day = index + 1
      return DailyReading(
        id: "jonah-\(day)",
        day: day,
        title: "Jonah \(day)",
        references: [
          VerseReference(
            bookName: "Jonah",
            chapter: day,
            startVerse: 1,
            endVerse: count
          ),
        ]
      )
    }
  }

  private func createRuthsStoryReadings() -> [DailyReading] {
    let verseCounts = [22, 23, 18, 22]

    return verseCounts.enumerated().map { index, count in
      let day = index + 1
      return DailyReading(
        id: "ruth-\(day)",
        day: day,
        title: "Ruth \(day)",
        references: [
          VerseReference(
            bookName: "Ruth",
            chapter: day,
            startVerse: 1,
            endVerse: count
          ),
        ]
      )
    }
  }

  private func createSermonOnTheMountReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "Matthew 5", [("Matthew", 5, 1, 48)]),
      (2, "Matthew 6", [("Matthew", 6, 1, 34)]),
      (3, "Matthew 7", [("Matthew", 7, 1, 29)])
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "sermon-mount-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createCreationWeekReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "Day 1", [("Genesis", 1, 1, 5)]),
      (2, "Day 2", [("Genesis", 1, 6, 8)]),
      (3, "Day 3", [("Genesis", 1, 9, 13)]),
      (4, "Day 4", [("Genesis", 1, 14, 19)]),
      (5, "Day 5", [("Genesis", 1, 20, 23)]),
      (6, "Day 6", [("Genesis", 1, 24, 31)]),
      (7, "Day 7", [("Genesis", 2, 1, 3)])
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "creation-week-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createPaulsPrayersReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "Ephesians 1:15-23", [("Ephesians", 1, 15, 23)]),
      (2, "Ephesians 3:14-21", [("Ephesians", 3, 14, 21)]),
      (3, "Philippians 1:3-11", [("Philippians", 1, 3, 11)]),
      (4, "Colossians 1:9-14", [("Colossians", 1, 9, 14)]),
      (5, "1 Thessalonians 3:9-13", [("1 Thessalonians", 3, 9, 13)]),
      (6, "2 Thessalonians 1:11-12", [("2 Thessalonians", 1, 11, 12)]),
      (7, "Philemon 1:4-7", [("Philemon", 1, 4, 7)])
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "paul-prayers-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createFruitOfSpiritReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "Love", [("1 Corinthians", 13, 4, 7)]),
      (2, "Joy", [("John", 15, 9, 11)]),
      (3, "Peace", [("Philippians", 4, 6, 7)]),
      (4, "Patience", [("James", 5, 7, 8)]),
      (5, "Kindness", [("Ephesians", 4, 31, 32)]),
      (6, "Goodness", [("Galatians", 6, 9, 10)]),
      (7, "Faithfulness", [("Hebrews", 10, 23, 23)]),
      (8, "Gentleness", [("Colossians", 3, 12, 13)]),
      (9, "Self-Control", [("1 Corinthians", 9, 24, 27)])
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "fruit-spirit-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createTenCommandmentsReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "No Other Gods", [("Exodus", 20, 1, 3)]),
      (2, "No Idols", [("Exodus", 20, 4, 6)]),
      (3, "Honor God's Name", [("Exodus", 20, 7, 7)]),
      (4, "Keep the Sabbath", [("Exodus", 20, 8, 11)]),
      (5, "Honor Parents", [("Exodus", 20, 12, 12)]),
      (6, "Do Not Murder", [("Exodus", 20, 13, 13)]),
      (7, "Do Not Commit Adultery", [("Exodus", 20, 14, 14)]),
      (8, "Do Not Steal", [("Exodus", 20, 15, 15)]),
      (9, "Do Not Lie", [("Exodus", 20, 16, 16)]),
      (10, "Do Not Covet", [("Exodus", 20, 17, 17)])
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "ten-commandments-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }

  private func createProverbsWisdomReadings() -> [DailyReading] {
    let verseCounts = [33, 22, 35, 27, 23, 35, 27]

    return verseCounts.enumerated().map { index, count in
      let day = index + 1
      return DailyReading(
        id: "proverbs-wisdom-\(day)",
        day: day,
        title: "Proverbs \(day)",
        references: [
          VerseReference(bookName: "Proverbs", chapter: day, startVerse: 1, endVerse: count)
        ]
      )
    }
  }

  private func createWomenOfFaithReadings() -> [DailyReading] {
    let readingsData: [(Int, String, [(String, Int, Int, Int)])] = [
      (1, "Mary (Luke 1)", [("Luke", 1, 26, 38)]),
      (2, "Ruth", [("Ruth", 1, 1, 22)]),
      (3, "Esther", [("Esther", 4, 13, 17)]),
      (4, "Hannah", [("1 Samuel", 1, 10, 20)]),
      (5, "Deborah", [("Judges", 4, 4, 9)]),
      (6, "Sarah", [("Genesis", 18, 1, 15)]),
      (7, "Mary Magdalene", [("John", 20, 1, 18)])
    ]

    return readingsData.map { reading in
      DailyReading(
        id: "women-faith-\(reading.0)",
        day: reading.0,
        title: reading.1,
        references: reading.2.map { ref in
          VerseReference(bookName: ref.0, chapter: ref.1, startVerse: ref.2, endVerse: ref.3)
        }
      )
    }
  }
}

// MARK: - Reading Plans Main View
struct ReadingPlansView: View {
  @StateObject private var plansManager = ReadingPlansManager()
  @EnvironmentObject var settings: UserSettings
  @State private var selectedTab = 0  // 0: Active, 1: Browse
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    VStack(spacing: 0) {
      // Header (Updated with smaller styling)
      VStack(spacing: 16) {
        VStack(spacing: 8) {
          HStack {
            Image(systemName: "book.circle.fill")
              .font(.system(size: 24))
              .foregroundColor(.blue)

            Text("Reading Plans")
              .font(.title2)
              .fontWeight(.bold)
          }

          Text("Guided spiritual journeys through Scripture")
            .font(.caption)
            .foregroundColor(.secondary)
        }

        // Tab Selector (Updated with smaller styling)
        HStack(spacing: 0) {
          ReadingPlansTabButton(
            title: "Active",
            isSelected: selectedTab == 0,
            action: { selectedTab = 0 }
          )

          ReadingPlansTabButton(
            title: "Browse Plans",
            isSelected: selectedTab == 1,
            action: { selectedTab = 1 }
          )
        }
        .padding(3)
        .background(colorScheme == .light ? Color.black.opacity(0.05) : Color.white.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
      .padding()
      .background(Color(.systemGroupedBackground))

      // Content
      TabView(selection: $selectedTab) {
        ActivePlansView()
          .environmentObject(plansManager)
          .tag(0)

        BrowsePlansView()
          .environmentObject(plansManager)
          .tag(1)
      }
      .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
  }
}

// MARK: - Reading Plans Tab Button (Updated to match Bible Study styling)
struct ReadingPlansTabButton: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(isSelected ? .white : .primary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 6)
            .fill(isSelected ? Color.blue : Color.clear)
        )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Active Plans View
struct ActivePlansView: View {
  @EnvironmentObject var plansManager: ReadingPlansManager
  @EnvironmentObject var settings: UserSettings

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        if plansManager.activePlans.isEmpty {
          // Empty State
          VStack(spacing: 20) {
            Image(systemName: "book.closed")
              .font(.system(size: 60))
              .foregroundColor(.secondary.opacity(0.5))

            Text("No Active Plans")
              .font(.title2)
              .fontWeight(.semibold)

            Text("Browse plans to start your spiritual journey")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
          }
          .padding(.top, 100)
        } else {
          LazyVStack(spacing: 16) {
            ForEach(plansManager.activePlans) { plan in
              ActivePlanCard(plan: plan)
                .environmentObject(plansManager)
            }
          }
          .padding(.horizontal)
          .padding(.top)
        }
      }
      .frame(maxWidth: .infinity)
    }
    .background(Color(.systemGroupedBackground))
  }
}

// MARK: - Browse Plans View
struct BrowsePlansView: View {
  @EnvironmentObject var plansManager: ReadingPlansManager
  @State private var selectedCategory: PlanCategory? = nil

  var filteredPlans: [ReadingPlan] {
    if let category = selectedCategory {
      return plansManager.availablePlans.filter { $0.category == category }
    }
    return plansManager.availablePlans
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        // Category Filter
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            CategoryChip(
              title: "All",
              isSelected: selectedCategory == nil,
              action: { selectedCategory = nil }
            )

            ForEach(PlanCategory.allCases, id: \.rawValue) { category in
              CategoryChip(
                title: category.rawValue,
                isSelected: selectedCategory == category,
                action: { selectedCategory = category }
              )
            }
          }
          .padding(.horizontal)
        }

        // Plans Grid
        LazyVStack(spacing: 16) {
          ForEach(filteredPlans) { plan in
            PlanBrowseCard(plan: plan)
              .environmentObject(plansManager)
          }
        }
        .padding(.horizontal)
      }
      .padding(.top)
    }
    .background(Color(.systemGroupedBackground))
  }
}

// MARK: - Category Chip Component
struct CategoryChip: View {
  let title: String
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Text(title)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(isSelected ? .white : .primary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
          Capsule()
            .fill(isSelected ? Color.blue : Color(.systemGray5))
        )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Active Plan Card
struct ActivePlanCard: View {
  let plan: ReadingPlan
  @EnvironmentObject var plansManager: ReadingPlansManager
  @State private var showingPlanDetail = false

  var nextReading: DailyReading? {
    plansManager.getNextUnreadDay(for: plan.id)
  }
  
  var actualCompletedDays: Int {
    plansManager.getActualCompletedDays(for: plan.id)
  }
  
  var actualProgress: Double {
    plansManager.getActualProgressPercentage(for: plan.id)
  }

  var body: some View {
    Button(action: {
      showingPlanDetail = true
    }) {
      VStack(alignment: .leading, spacing: 16) {
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text(plan.title)
              .font(.headline)
              .foregroundColor(.primary)

            Text("\(actualCompletedDays) of \(plan.readings.count) days")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }

          Spacer()

          Image(systemName: plan.icon)
            .font(.system(size: 24))
            .foregroundColor(plan.color.color)
        }

        // Progress Bar
        VStack(alignment: .leading, spacing: 8) {
          HStack {
            Text("Progress")
              .font(.caption)
              .foregroundColor(.secondary)

            Spacer()

            Text("\(Int(actualProgress * 100))%")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          ProgressView(value: actualProgress)
            .tint(plan.color.color)
        }

        // Next Reading
        if let next = nextReading {
          HStack {
            Text("Next:")
              .font(.caption)
              .foregroundColor(.secondary)

            Text("Day \(next.day) - \(next.title)")
              .font(.caption)
              .fontWeight(.medium)
              .foregroundColor(plan.color.color)

            Spacer()
          }
        }
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.secondarySystemGroupedBackground))
          .shadow(color: plan.color.color.opacity(0.1), radius: 8, x: 0, y: 4)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(
            LinearGradient(
              gradient: Gradient(colors: [
                plan.color.color.opacity(0.3),
                plan.color.color.opacity(0.1),
              ]),
              startPoint: .topLeading,
              endPoint: .bottomTrailing
            ),
            lineWidth: 1
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
    .sheet(isPresented: $showingPlanDetail) {
      PlanDetailView(plan: plan)
        .environmentObject(plansManager)
    }
  }
}

// MARK: - Plan Browse Card
struct PlanBrowseCard: View {
  let plan: ReadingPlan
  @EnvironmentObject var plansManager: ReadingPlansManager
  @State private var showingPlanDetail = false

  var isActive: Bool {
    plansManager.activePlans.contains { $0.id == plan.id }
  }

  var body: some View {
    Button(action: {
      showingPlanDetail = true
    }) {
      HStack(spacing: 16) {
        // Plan Icon
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(
              LinearGradient(
                gradient: Gradient(colors: [
                  plan.color.color,
                  plan.color.color.opacity(0.7),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 60, height: 60)

          Image(systemName: plan.icon)
            .font(.system(size: 24))
            .foregroundColor(.white)
        }

        // Plan Info
        VStack(alignment: .leading, spacing: 4) {
          Text(plan.title)
            .font(.headline)
            .foregroundColor(.primary)

          Text(plan.description)
            .font(.subheadline)
            .foregroundColor(.secondary)
            .lineLimit(2)

          HStack {
            Text("\(plan.duration) days")
              .font(.caption)
              .foregroundColor(plan.color.color)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(
                Capsule()
                  .fill(plan.color.color.opacity(0.1))
              )

            Text(plan.category.rawValue)
              .font(.caption)
              .foregroundColor(.secondary)

            Spacer()

            if isActive {
              Text("Active")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.green)
            }
          }
        }

        // Chevron
        Image(systemName: "chevron.right")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.secondarySystemGroupedBackground))
      )
    }
    .buttonStyle(PlainButtonStyle())
    .sheet(isPresented: $showingPlanDetail) {
      PlanDetailView(plan: plan)
        .environmentObject(plansManager)
    }
  }
}

// MARK: - Plan Detail View
struct PlanDetailView: View {
  let plan: ReadingPlan
  @EnvironmentObject var plansManager: ReadingPlansManager
  @EnvironmentObject var settings: UserSettings
  @Environment(\.dismiss) private var dismiss
  @State private var showingStartAlert = false
  @State private var showAllReadings = false

  var activePlan: ReadingPlan? {
    plansManager.activePlans.first { $0.id == plan.id }
  }

  var isActive: Bool {
    activePlan != nil
  }

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          // Header
          VStack(spacing: 16) {
            ZStack {
              RoundedRectangle(cornerRadius: 20)
                .fill(
                  LinearGradient(
                    gradient: Gradient(colors: [
                      plan.color.color,
                      plan.color.color.opacity(0.7),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
                .frame(width: 80, height: 80)

              Image(systemName: plan.icon)
                .font(.system(size: 36))
                .foregroundColor(.white)
            }

            VStack(spacing: 8) {
              Text(plan.title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

              Text(plan.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            }

            HStack(spacing: 20) {
              StatItem(title: "Days", value: "\(plan.readings.count)")
              StatItem(title: "Category", value: plan.category.rawValue)
            }
          }
          .padding()

          // Progress (if active)
          if let activePlan = activePlan {
            VStack(spacing: 16) {
              Text("Your Progress")
                .font(.headline)

              VStack(spacing: 8) {
                HStack {
                  Text("\(plansManager.getActualCompletedDays(for: plan.id)) of \(activePlan.readings.count) days completed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                  Spacer()

                  Text("\(Int(plansManager.getActualProgressPercentage(for: plan.id) * 100))%")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(plan.color.color)
                }

                ProgressView(value: plansManager.getActualProgressPercentage(for: plan.id))
                  .tint(plan.color.color)
              }
            }
            .padding()
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
            )
            .padding(.horizontal)
          }

          // Enhanced Reading Schedule
          VStack(alignment: .leading, spacing: 16) {
            HStack {
              Text("Reading Schedule")
                .font(.headline)
              
              Spacer()
              
              if plan.readings.count > 5 && !showAllReadings {
                Button(action: {
                  withAnimation(.easeInOut(duration: 0.3)) {
                    showAllReadings = true
                  }
                }) {
                  Text("Show All")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
              }
            }
            .padding(.horizontal)

            LazyVStack(spacing: 8) {
              let readingsToShow = showAllReadings ? plan.readings : Array(plan.readings.prefix(5))
              
              ForEach(readingsToShow) { reading in
                if isActive {
                  // Active plan - clickable readings
                  NavigationLink(destination: ReadingDetailView(reading: reading, plan: plan)) {
                    EnhancedReadingRow(
                      reading: reading,
                      plan: plan,
                      isCompleted: activePlan?.readings.first(where: { $0.id == reading.id })?.isCompleted ?? false,
                      showProgress: true
                    )
                  }
                  .buttonStyle(PlainButtonStyle())
                } else {
                  // Inactive plan - preview only
                  EnhancedReadingRow(
                    reading: reading,
                    plan: plan,
                    isCompleted: false,
                    showProgress: false
                  )
                }
              }

              if !showAllReadings && plan.readings.count > 5 {
                Button(action: {
                  withAnimation(.easeInOut(duration: 0.3)) {
                    showAllReadings = true
                  }
                }) {
                  HStack {
                    Text("Show \(plan.readings.count - 5) more days")
                      .font(.subheadline)
                      .fontWeight(.medium)
                      .foregroundColor(.blue)
                    
                    Image(systemName: "chevron.down")
                      .font(.system(size: 12))
                      .foregroundColor(.blue)
                  }
                  .padding(.vertical, 12)
                  .frame(maxWidth: .infinity)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .fill(Color.blue.opacity(0.1))
                  )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
              }
              
              if showAllReadings && plan.readings.count > 5 {
                Button(action: {
                  withAnimation(.easeInOut(duration: 0.3)) {
                    showAllReadings = false
                  }
                }) {
                  HStack {
                    Text("Show less")
                      .font(.subheadline)
                      .fontWeight(.medium)
                      .foregroundColor(.blue)
                    
                    Image(systemName: "chevron.up")
                      .font(.system(size: 12))
                      .foregroundColor(.blue)
                  }
                  .padding(.vertical, 12)
                  .frame(maxWidth: .infinity)
                  .background(
                    RoundedRectangle(cornerRadius: 8)
                      .fill(Color.blue.opacity(0.1))
                  )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal)
              }
            }
          }

          Spacer(minLength: 100)
        }
      }
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Close") {
            dismiss()
          }
        }
      }
      .safeAreaInset(edge: .bottom) {
        // Action Button
        VStack(spacing: 12) {
          if isActive {
            if let nextReading = plansManager.getNextUnreadDay(for: plan.id) {
              NavigationLink(destination: ReadingDetailView(reading: nextReading, plan: plan)) {
                HStack {
                  Text("Continue Reading")
                  Spacer()
                  Text("Day \(nextReading.day)")
                    .foregroundColor(.white.opacity(0.8))
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(plan.color.color)
                )
              }
              .buttonStyle(PlainButtonStyle())
            } else {
              // Plan completed
              HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Plan Completed!")
                Spacer()
              }
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(.green)
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(Color.green.opacity(0.1))
                  .overlay(
                    RoundedRectangle(cornerRadius: 12)
                      .stroke(Color.green, lineWidth: 2)
                  )
              )
            }

            Button("Remove Plan") {
              plansManager.removePlan(plan.id)
              dismiss()
            }
            .foregroundColor(.red)
            .font(.system(size: 16, weight: .medium))
          } else {
            Button(action: {
              showingStartAlert = true
            }) {
              HStack {
                Image(systemName: "play.fill")
                Text("Start Plan")
              }
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(
                RoundedRectangle(cornerRadius: 12)
                  .fill(plan.color.color)
              )
            }
          }
        }
        .padding()
        .background(.ultraThinMaterial)
      }
    }
    .alert("Start Reading Plan?", isPresented: $showingStartAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Start") {
        plansManager.startPlan(plan)
        dismiss()
      }
    } message: {
      Text("This will add \"\(plan.title)\" to your active reading plans.")
    }
  }
}

// MARK: - Supporting Views
struct StatItem: View {
  let title: String
  let value: String

  var body: some View {
    VStack(spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
      Text(value)
        .font(.subheadline)
        .fontWeight(.medium)
    }
  }
}

// MARK: - Enhanced Reading Row with Progress
struct EnhancedReadingRow: View {
  let reading: DailyReading
  let plan: ReadingPlan
  let isCompleted: Bool
  let showProgress: Bool

  // Calculate verse completion progress if this is an active plan
  private func getVerseProgress() -> (completed: Int, total: Int) {
    if showProgress {
      // This would ideally come from saved verse completion data
      let key = "completed_verses_\(plan.id)_\(reading.day)"
      if let data = UserDefaults.standard.array(forKey: key) as? [String] {
        // Estimate total verses from references
        let estimatedTotal = reading.references.reduce(0) { total, ref in
          total + (ref.endVerse - ref.startVerse + 1)
        }
        return (completed: data.count, total: max(estimatedTotal, data.count))
      }
    }
    return (completed: 0, total: 0)
  }

  var body: some View {
    HStack(spacing: 12) {
      // Day number with completion status
      ZStack {
        Circle()
          .fill(isCompleted ? plan.color.color : Color(.systemGray5))
          .frame(width: 36, height: 36)

        if isCompleted {
          Image(systemName: "checkmark")
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.white)
        } else {
          Text("\(reading.day)")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.primary)
        }
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(reading.title)
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(isCompleted ? .secondary : .primary)

        Text(reading.references.map { $0.shortDisplayText }.joined(separator: ", "))
          .font(.caption)
          .foregroundColor(.secondary)
          .lineLimit(1)
        
        // Progress bar for active plans
        if showProgress && !isCompleted {
          let progress = getVerseProgress()
          if progress.total > 0 {
            VStack(spacing: 2) {
              HStack {
                Text("\(progress.completed) of \(progress.total) verses")
                  .font(.caption2)
                  .foregroundColor(.secondary)
                Spacer()
              }
              
              ProgressView(value: Double(progress.completed), total: Double(progress.total))
                .tint(plan.color.color)
                .scaleEffect(y: 0.8)
            }
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading) 

      // Chevron for clickable rows
      if showProgress {
        Image(systemName: "chevron.right")
          .font(.system(size: 12))
          .foregroundColor(.secondary)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 8)
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: 12)
        .fill(showProgress ? Color(.tertiarySystemGroupedBackground) : Color.clear)
    )
  }
}

struct ReadingPreviewRow: View {
  let reading: DailyReading
  let plan: ReadingPlan
  let isCompleted: Bool

  var body: some View {
    EnhancedReadingRow(
      reading: reading,
      plan: plan,
      isCompleted: isCompleted,
      showProgress: false
    )
  }
}

