import StoreKit
import SwiftUI

struct MoreView: View {
  @AppStorage("appearanceMode") private var appearanceMode = "system"
  @State private var settingsPath = NavigationPath()

  var body: some View {
    NavigationStack(path: $settingsPath) {
      ScrollView {
        VStack(spacing: 24) {
          // Personal Section
          SectionContainer(title: "Personal", icon: "person.circle") {
            VStack(spacing: 8) {
              NavigationLinkRow(
                title: "Saved Quotes",
                subtitle: "Your favorite wisdom",
                icon: "quote.bubble.fill",
                iconColor: .teal,
                destination: SavedQuotesView()
              )

              NavigationLinkRow(
                title: "Verse of the Day",
                subtitle: "Daily verse history",
                icon: "calendar.badge.clock",
                iconColor: .orange,
                destination: VerseOfTheDayView()
              )

              NavigationLinkRow(
                title: "Prayers",
                subtitle: "Your prayer journal",
                icon: "hands.sparkles.fill",
                iconColor: .purple,
                destination: PrayerView()
              )

              NavigationLinkRow(
                title: "App Activity",
                subtitle: "Reading progress",
                icon: "chart.bar.fill",
                iconColor: .green,
                destination: AppActivityView()
              )
            }
          }

          // Sharing Section
          SectionContainer(title: "Share", icon: "heart.circle") {
            VStack(spacing: 8) {
              NavigationLinkRow(
                title: "Share App",
                subtitle: "Tell others about Zen Every Day",
                icon: "square.and.arrow.up",
                iconColor: .indigo,
                destination: ShareAppView()
              )

              ButtonRow(
                title: "Rate App",
                subtitle: "Help us improve",
                icon: "star.fill",
                iconColor: .yellow,
                action: rateApp
              )

            }
          }

          // Settings Section
          SectionContainer(title: "Settings & Info", icon: "gear.circle") {
            VStack(spacing: 8) {
              NavigationLinkRow(
                title: "Settings",
                subtitle: "Customize your experience",
                icon: "gear",
                iconColor: .gray,
                destination: SettingsView()
              )

              NavigationLinkRow(
                title: "About",
                subtitle: "App info and policies",
                icon: "info.circle",
                iconColor: .blue,
                destination: AboutView()
              )
            }
          }
        }
        .padding(.horizontal)
        .padding(.vertical, 24)
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
    }
  }

  private func rateApp() {
    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
      SKStoreReviewController.requestReview(in: scene)
    }
  }
}

// MARK: - Supporting Views

struct SectionContainer<Content: View>: View {
  let title: String
  let icon: String
  let content: Content

  init(title: String, icon: String, @ViewBuilder content: () -> Content) {
    self.title = title
    self.icon = icon
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Section Header - Made larger and more prominent
      HStack(spacing: 10) {
        Image(systemName: icon)
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(.blue)

        Text(title)
          .font(.title3)
          .fontWeight(.semibold)

        Spacer()
      }
      .padding(.horizontal, 4)

      // Section Content
      VStack(spacing: 0) {
        content
      }
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.secondarySystemGroupedBackground))
          .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(
                Color.primary.opacity(0.08),
                lineWidth: 0.5
              )
          )
      )
    }
  }
}

struct NavigationLinkRow<Destination: View>: View {
  let title: String
  let subtitle: String
  let icon: String
  let iconColor: Color
  let destination: Destination

  var body: some View {
    NavigationLink(destination: destination) {
      HStack(spacing: 12) {
        // Icon
        ZStack {
          Circle()
            .fill(iconColor.opacity(0.1))
            .frame(width: 36, height: 36)

          Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(iconColor)
        }

        // Text Content
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary)

          Text(subtitle)
            .font(.system(size: 13))
            .foregroundColor(.secondary)
        }

        Spacer()

        // Chevron
        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.secondary.opacity(0.6))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .contentShape(Rectangle())
    }
    .buttonStyle(RowButtonStyle())
  }
}

struct ButtonRow: View {
  let title: String
  let subtitle: String
  let icon: String
  let iconColor: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        // Icon
        ZStack {
          Circle()
            .fill(iconColor.opacity(0.1))
            .frame(width: 36, height: 36)

          Image(systemName: icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(iconColor)
        }

        // Text Content
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.primary)

          Text(subtitle)
            .font(.system(size: 13))
            .foregroundColor(.secondary)
        }

        Spacer()

        // Chevron
        Image(systemName: "chevron.right")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(.secondary.opacity(0.6))
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .contentShape(Rectangle())
    }
    .buttonStyle(RowButtonStyle())
  }
}

struct RowButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .background(
        Color.primary.opacity(configuration.isPressed ? 0.05 : 0)
      )
      .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
  }
}

struct MoreView_Previews: PreviewProvider {
  static var previews: some View {
    MoreView()
  }
}
