import SwiftUI
import UIKit

// Enhanced Topic model with visual properties
struct TopicItem {
  let id = UUID()
  let name: String
  let keyword: String
  let icon: String
  let color: Color
  let gradient: [Color]
  let description: String
}

struct TopicsView: View {
  @EnvironmentObject var settings: UserSettings
  @State private var path = NavigationPath()

  let topics: [TopicItem] = [
    TopicItem(
      name: "Mindfulness",
      keyword: "mindfulness",
      icon: "eye",
      color: .green,
      gradient: [.green, .mint],
      description: "Awareness of the present moment"
    ),
    TopicItem(
      name: "Compassion",
      keyword: "compassion",
      icon: "heart.fill",
      color: .red,
      gradient: [.red, .pink],
      description: "Caring for all beings"
    ),
    TopicItem(
      name: "Wisdom",
      keyword: "wisdom",
      icon: "lightbulb.fill",
      color: .purple,
      gradient: [.purple, .indigo],
      description: "Insight into the nature of reality"
    ),
    TopicItem(
      name: "Impermanence",
      keyword: "impermanence",
      icon: "clock",
      color: .orange,
      gradient: [.orange, .yellow],
      description: "Understanding change"
    ),
    TopicItem(
      name: "Suffering",
      keyword: "suffering",
      icon: "exclamationmark.triangle.fill",
      color: .yellow,
      gradient: [.yellow, .orange],
      description: "Recognizing and easing dukkha"
    ),
    TopicItem(
      name: "Peace",
      keyword: "peace",
      icon: "leaf.fill",
      color: .mint,
      gradient: [.mint, .teal],
      description: "Calmness and serenity"
    ),
    TopicItem(
      name: "Generosity",
      keyword: "generosity",
      icon: "hands.sparkles.fill",
      color: .mint,
      gradient: [.mint, .green],
      description: "Joy of giving",
    ),
    TopicItem(
      name: "Equanimity",
      keyword: "equanimity",
      icon: "yinyang",
      color: .teal,
      gradient: [.teal, .blue],
      description: "Balanced mind in all conditions",
    ),
    TopicItem(
      name: "Patience",
      keyword: "patience",
      icon: "hourglass",
      color: .brown,
      gradient: [.brown, .orange],
      description: "Calm endurance through challenges",
    ),
    TopicItem(
      name: "Non-Attachment",
      keyword: "non-attachment",
      icon: "scissors",
      color: .indigo,
      gradient: [.indigo, .blue],
      description: "Letting go of clinging",
    ),
    TopicItem(
      name: "Joy",
      keyword: "joy",
      icon: "face.smiling",
      color: .pink,
      gradient: [.pink, .orange],
      description: "Cultivating gladness",
    ),
  ]

  let columns = [
    GridItem(.flexible(), spacing: 16),
    GridItem(.flexible(), spacing: 16),
  ]

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        VStack(spacing: 24) {
          // Header Section
          VStack(spacing: 16) {
            // Title and Icon
            VStack(spacing: 12) {
              ZStack {
                Circle()
                  .fill(
                    LinearGradient(
                      gradient: Gradient(colors: [.blue, .purple]),
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing
                    )
                  )
                  .frame(width: 64, height: 64)

                Image(systemName: "square.grid.2x2.fill")
                  .font(.system(size: 28))
                  .foregroundColor(.white)
              }

              VStack(spacing: 4) {
                Text("Buddhist Topics")
                  .font(.largeTitle)
                  .fontWeight(.bold)

                Text("Explore the teachings by theme")
                  .font(.subheadline)
                  .foregroundColor(.secondary)
              }
            }
          }
          .padding(.top, 20)

          // Topics Grid
          LazyVGrid(columns: columns, spacing: 16) {
            ForEach(topics, id: \.id) { topic in
              TopicCard(topic: topic) {
                // Convert TopicItem to Topic for navigation
                path.append(topic.asLegacyTopic)
              }
            }
          }
          .padding(.horizontal)

          // Footer
          VStack(spacing: 8) {
            Text("Discover quotes organized by themes")
              .font(.caption)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)

            Text("Each topic contains carefully selected teachings")
              .font(.caption2)
              .foregroundColor(.secondary.opacity(0.7))
          }
          .padding(.bottom, 40)
        }
      }
      .background(
        LinearGradient(
          gradient: Gradient(colors: [
            Color(.systemGroupedBackground),
            Color(.systemBackground),
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
      )
      .navigationTitle("")
      .navigationBarTitleDisplayMode(.inline)
      .navigationDestination(for: Topic.self) { topic in
        TopicDetailView(topic: topic)
      }
    }
  }
}

struct TopicCard: View {
  let topic: TopicItem
  let action: () -> Void
  @State private var isPressed = false

  var body: some View {
    Button(action: action) {
      VStack(spacing: 0) {
        // Icon and gradient header
        VStack(spacing: 12) {
          ZStack {
            // Background gradient
            RoundedRectangle(cornerRadius: 20)
              .fill(
                LinearGradient(
                  gradient: Gradient(colors: topic.gradient),
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 38, height: 38)

            // Icon
            Image(systemName: topic.icon)
              .font(.system(size: 24, weight: .semibold))
              .foregroundColor(.white)
          }

          VStack(spacing: 4) {
            Text(topic.name)
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.primary)

            Text(topic.description)
              .font(.system(size: 12))
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)
              .lineLimit(2)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, minHeight: 105)
        .background(
          RoundedRectangle(cornerRadius: 20)
            .fill(Color(.secondarySystemGroupedBackground))
            .shadow(
              color: topic.color.opacity(0.2),
              radius: isPressed ? 8 : 12,
              x: 0,
              y: isPressed ? 2 : 6
            )
        )
        .overlay(
          RoundedRectangle(cornerRadius: 20)
            .stroke(
              LinearGradient(
                gradient: Gradient(colors: [
                  topic.color.opacity(0.3),
                  topic.color.opacity(0.1),
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              ),
              lineWidth: 1
            )
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
      }
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

// Convert TopicItem to legacy Topic for navigation compatibility
extension TopicItem {
  var asLegacyTopic: Topic {
    return Topic(name: self.name, keyword: self.keyword)
  }
}

struct TopicsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      TopicsView()
        .environmentObject(UserSettings())
    }
  }
}

