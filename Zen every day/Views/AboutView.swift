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

          Text("Daily Bible")
            .font(.largeTitle)
            .fontWeight(.bold)

          Text("Version 1.0")
            .font(.caption)
            .foregroundColor(.secondary)

          // Highlighted tagline
          Text(
            "A beautifully simple, modern Bible app that's completely free with no ads, no subscriptions, and no distractions – just pure scripture at your fingertips."
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
              "Daily Bible is a complimentary application designed to facilitate Bible study and spiritual enrichment. This application provides users with carefully curated biblical texts, comprehensive study tools, and daily devotional content. Whether you are deepening your existing faith journey or exploring spirituality for the first time, Daily Bible offers convenient access to inspirational scriptures and thoughtful theological insights to enhance your spiritual growth and understanding."
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

              All biblical text contained within this application is sourced from the Authorized King James Version (KJV), which resides in the public domain. No copyright infringement is intended or implied through the use of these texts.
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
            Text("© 2025 Daily Bible")
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
