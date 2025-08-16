import SwiftUI

struct StudyView: View {
  var body: some View {
    TopicalStudyView()
  }
}

struct TopicalStudyView: View {
  @EnvironmentObject var settings: UserSettings
  @State private var path = NavigationPath()

  // Buddhist topic categories
  let topicCategories: [TopicCategory] = [
    TopicCategory(
      name: "Core Teachings",
      icon: "sun.max.fill",
      color: .orange,
      topics: [
        TopicItem(
          name: "Four Noble Truths", keyword: "four noble truths", icon: "4.square.fill", color: .orange,
          gradient: [.orange, .yellow], description: "Understanding suffering and its cessation"),
        TopicItem(
          name: "Noble Eightfold Path", keyword: "eightfold", icon: "8.square.fill", color: .blue,
          gradient: [.blue, .indigo], description: "The path to liberation"),
        TopicItem(
          name: "Impermanence", keyword: "impermanence", icon: "clock", color: .pink,
          gradient: [.pink, .purple], description: "All things change"),
      ]
    ),
    TopicCategory(
      name: "Virtues",
      icon: "heart.fill",
      color: .red,
      topics: [
        TopicItem(
          name: "Compassion", keyword: "compassion", icon: "heart.fill", color: .red,
          gradient: [.red, .pink], description: "Caring for all beings"),
        TopicItem(
          name: "Mindfulness", keyword: "mindfulness", icon: "eye", color: .green,
          gradient: [.green, .mint], description: "Awareness of the present"),
        TopicItem(
          name: "Wisdom", keyword: "wisdom", icon: "lightbulb.fill", color: .purple,
          gradient: [.purple, .indigo], description: "Insight into reality"),
      ]
    ),
    TopicCategory(
      name: "Practice Qualities",
      icon: "brain.head.profile",
      color: .teal,
      topics: [
        TopicItem(
          name: "Generosity", keyword: "generosity", icon: "hands.sparkles.fill", color: .mint,
          gradient: [.mint, .green], description: "Joy of giving"),
        TopicItem(
          name: "Equanimity", keyword: "equanimity", icon: "yinyang", color: .teal,
          gradient: [.teal, .blue], description: "Balanced mind in all conditions"),
        TopicItem(
          name: "Patience", keyword: "patience", icon: "hourglass", color: .brown,
          gradient: [.brown, .orange], description: "Calm endurance"),
      ]
    ),
  ]

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        LazyVStack(spacing: 24) {
          // Introduction section
          VStack(spacing: 16) {
            HStack {
              Image(systemName: "lightbulb.fill")
                .foregroundColor(.orange)
              Text("Explore by Theme")
                .font(.headline)
                .fontWeight(.semibold)
              Spacer()
            }

            Text("Discover teachings on life's important topics")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.horizontal)
          .padding(.top)

          // Topic categories
          ForEach(topicCategories, id: \.name) { category in
            TopicCategorySection(category: category, path: $path)
          }

          Spacer(minLength: 40)
        }
      }
      .background(Color(.systemGroupedBackground))
      .navigationDestination(for: Topic.self) { topic in
        TopicDetailView(topic: topic)
      }
    }
  }
}

struct TopicCategory {
  let name: String
  let icon: String
  let color: Color
  let topics: [TopicItem]
}

struct TopicCategorySection: View {
  let category: TopicCategory
  @Binding var path: NavigationPath

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Category header
      HStack(spacing: 12) {
        ZStack {
          Circle()
            .fill(category.color.opacity(0.1))
            .frame(width: 40, height: 40)

          Image(systemName: category.icon)
            .font(.system(size: 18))
            .foregroundColor(category.color)
        }

        Text(category.name)
          .font(.title3)
          .fontWeight(.semibold)

        Spacer()
      }
      .padding(.horizontal)

      // Topics in this category
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 16) {
          Color.clear.frame(width: 1)

          ForEach(category.topics, id: \.id) { topic in
            CompactTopicCard(topic: topic) {
              path.append(topic.asLegacyTopic)
            }
          }

          Color.clear.frame(width: 1)
        }
        .padding(.vertical, 16)
      }
      .padding(.horizontal, -1)
    }
  }
}

struct CompactTopicCard: View {
  let topic: TopicItem
  let action: () -> Void
  @State private var isPressed = false
  @Environment(\.colorScheme) var colorScheme

  var body: some View {
    Button(action: action) {
      VStack(spacing: 12) {
        // Icon
        ZStack {
          RoundedRectangle(cornerRadius: 12)
            .fill(
              LinearGradient(
                gradient: Gradient(colors: topic.gradient),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 38, height: 38)

          Image(systemName: topic.icon)
            .font(.system(size: 22, weight: .semibold))
            .foregroundColor(.white)
        }

        // Title
        VStack(spacing: 4) {
          Text(topic.name)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(1)

          Text(topic.description)
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
        }
      }
      .frame(width: 90, height: 105)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(colorScheme == .dark ? Color(.secondarySystemGroupedBackground) : Color.white)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 16)
          .stroke(
            colorScheme == .dark
              ? Color.white.opacity(0.1)
              : Color.gray.opacity(0.15),
            lineWidth: 1
          )
      )
      .shadow(
        color: colorScheme == .dark
          ? topic.color.opacity(0.3)
          : Color.black.opacity(0.08),
        radius: 8,
        x: 0,
        y: 4
      )
      .scaleEffect(isPressed ? 0.95 : 1.0)
      .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    .buttonStyle(PlainButtonStyle())
    .onLongPressGesture(
      minimumDuration: 0, maximumDistance: .infinity,
      pressing: { pressing in
        withAnimation(.easeInOut(duration: 0.1)) {
          isPressed = pressing
        }
      }, perform: {})
  }
}

