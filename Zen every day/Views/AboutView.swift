import SwiftUI

struct AboutView: View {
  @EnvironmentObject var settings: UserSettings

  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        // App Icon and Name Header
        VStack(spacing: 16) {
          Image(systemName: "book.closed.fill")
            .font(.system(size: 60))
            .foregroundColor(.blue)
            .padding()
            .background(
              Circle()
                .fill(Color.blue.opacity(0.1))
            )

          Text("Zen Every Day")
            .font(.largeTitle)
            .fontWeight(.bold)

          Text("Version 1.0")
            .font(.caption)
            .foregroundColor(.secondary)

          // Highlighted tagline
          Text(
            "A beautifully simple, modern Buddhist wisdom app that's completely free with no ads, no subscriptions, and no distractions – just pure inspiration at your fingertips."
          )
          .font(.system(size: settings.fontSize * 0.95, weight: .medium))
          .foregroundColor(.primary)
          .lineSpacing(4)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color(.secondarySystemGroupedBackground))
              .overlay(
                RoundedRectangle(cornerRadius: 8)
                  .stroke(Color.blue.opacity(0.15), lineWidth: 1)
              )
          )
          .padding(.top, 8)
        }
        .padding(.vertical, 40)

        // Content Sections
        VStack(spacing: 32) {
          // About Section
          VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "About", icon: "info.circle.fill")

            Text(
              "Zen Every Day is a complimentary application designed to share Buddhist wisdom and support mindful living. The app provides users with carefully curated teachings, inspirational quotes, and daily reflections. Whether you are deepening an existing practice or exploring mindfulness for the first time, Zen Every Day offers convenient access to insightful guidance for your journey."
            )
            .font(.system(size: settings.fontSize * 0.9))
            .foregroundColor(.primary.opacity(0.8))
            .lineSpacing(4)
          }

          Divider()
            .padding(.horizontal, -20)

          // Terms of Service Section
          VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Terms of Service", icon: "doc.text.fill")

            Text(
              """
              By accessing and using this application, you acknowledge and agree to be bound by the following terms and conditions:

              This application is provided "as is" without warranty of any kind, either express or implied, including but not limited to the implied warranties of merchantability, fitness for a particular purpose, or non-infringement. The developers, publishers, and distributors of this application shall not be liable for any direct, indirect, incidental, special, consequential, or punitive damages arising out of your access to, or use of, the application.

              All wisdom quotes contained within this application are adapted from Buddhist teachings and are released under the CC0 public domain dedication. No copyright infringement is intended or implied through the use of these texts.
              """
            )
            .font(.system(size: settings.fontSize * 0.9))
            .foregroundColor(.primary.opacity(0.8))
            .lineSpacing(4)
          }

          Divider()
            .padding(.horizontal, -20)

          // Privacy Policy Section
          VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Privacy Policy", icon: "lock.shield.fill")

            Text(
              """
              Your privacy is of paramount importance to us. This application has been designed with your privacy in mind:

              • No personal data is collected without your explicit consent
              • All application data is stored locally on your device
              • No information is transmitted to or shared with third parties
              • Your reading history and saved verses remain private and secure
              • Notification preferences are managed entirely on your device

              We are committed to maintaining the confidentiality and security of your personal information. This application does not employ analytics, tracking, or any form of data collection that could compromise your privacy.
              """
            )
            .font(.system(size: settings.fontSize * 0.9))
            .foregroundColor(.primary.opacity(0.8))
            .lineSpacing(4)
          }

          Divider()
            .padding(.horizontal, -20)

          // Contact Section
          VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Contact", icon: "envelope.fill")

            Text("For inquiries, support, or feedback, please contact us through the App Store.")
              .font(.system(size: settings.fontSize * 0.9))
              .foregroundColor(.primary.opacity(0.8))
              .lineSpacing(4)
          }

          // Copyright Footer
          VStack(spacing: 8) {
            Text("© 2025 Zen Every Day")
              .font(.caption)
              .foregroundColor(.secondary)

            Text("All Rights Reserved")
              .font(.caption2)
              .foregroundColor(.secondary)
          }
          .padding(.top, 20)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 40)
      }
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct SectionHeader: View {
  let title: String
  let icon: String

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 16))
        .foregroundColor(.blue)

      Text(title)
        .font(.headline)
        .foregroundColor(.primary)
    }
  }
}

struct AboutView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      AboutView()
        .environmentObject(UserSettings())
    }
  }
}
