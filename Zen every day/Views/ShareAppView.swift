import SwiftUI

struct ShareAppView: View {
  @EnvironmentObject var settings: UserSettings
  @State private var showingShareSheet = false
  @State private var showingCopiedAlert = false

  let appStoreLink = "https://apps.apple.com/app/zen-every-day/id123456789"  // Replace with your actual App Store ID
  let shareMessage =
    "I've been using Zen Every Day for daily Buddhist wisdom. It's a beautiful app with inspirational quotes. Check it out!"

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        VStack(spacing: 16) {
          Image(systemName: "square.and.arrow.up.circle.fill")
            .font(.system(size: 60))
            .foregroundColor(.blue)
            .padding()
            .background(
              Circle()
                .fill(Color.blue.opacity(0.1))
            )

          Text("Share Zen Every Day")
            .font(.title2)
            .fontWeight(.bold)

          Text("Spread the word and help others discover Zen Every Day")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
        }
        .padding(.top, 20)

        // Quick Share Button
        Button(action: {
          showingShareSheet = true
        }) {
          HStack {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 20))
            Text("Share App")
              .font(.headline)
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.blue)
          )
        }
        .padding(.horizontal)

        // Social Media Platforms
        VStack(alignment: .leading, spacing: 16) {
          Text("Share on Social Media")
            .font(.headline)
            .padding(.horizontal)

          VStack(spacing: 12) {
            SharePlatformButton(
              platform: "Messages",
              icon: "message.fill",
              color: .green,
              action: shareViaMessages
            )

            SharePlatformButton(
              platform: "WhatsApp",
              icon: "phone.fill",
              color: Color(red: 0.25, green: 0.85, blue: 0.46),
              action: shareViaWhatsApp
            )

            SharePlatformButton(
              platform: "Facebook",
              icon: "f.square.fill",
              color: Color(red: 0.26, green: 0.40, blue: 0.70),
              action: shareViaFacebook
            )

            SharePlatformButton(
              platform: "Twitter",
              icon: "bird.fill",
              color: Color(red: 0.11, green: 0.63, blue: 0.95),
              action: shareViaTwitter
            )

            SharePlatformButton(
              platform: "Instagram",
              icon: "camera.fill",
              color: Color(red: 0.88, green: 0.24, blue: 0.56),
              action: shareViaInstagram
            )

            SharePlatformButton(
              platform: "Email",
              icon: "envelope.fill",
              color: .blue,
              action: shareViaEmail
            )
          }
          .padding(.horizontal)
        }

        // App Link Section
        VStack(alignment: .leading, spacing: 12) {
          Text("App Store Link")
            .font(.headline)

          HStack {
            Text(appStoreLink)
              .font(.caption)
              .foregroundColor(.secondary)
              .lineLimit(1)
              .truncationMode(.middle)

            Spacer()

            Button(action: {
              UIPasteboard.general.string = appStoreLink
              showingCopiedAlert = true
            }) {
              Image(systemName: "doc.on.doc")
                .font(.system(size: 16))
                .foregroundColor(.blue)
            }
          }
          .padding()
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color(.systemGray6))
          )
        }
        .padding(.horizontal)

        // Share Statistics
        VStack(spacing: 16) {
          Text("Why Share?")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)

          VStack(alignment: .leading, spacing: 12) {
            BenefitRow(
              icon: "heart.fill",
              text: "Help others discover daily inspiration",
              color: .red
            )

            BenefitRow(
              icon: "person.2.fill",
              text: "Build a community of faith together",
              color: .blue
            )

            BenefitRow(
              icon: "sparkles",
              text: "Spread positivity and hope",
              color: .yellow
            )
          }
          .padding(.horizontal)
        }
        .padding(.bottom, 40)
      }
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingShareSheet) {
      ShareSheet(items: [shareMessage, URL(string: appStoreLink)!])
    }
    .alert("Link Copied!", isPresented: $showingCopiedAlert) {
      Button("OK", role: .cancel) {}
    } message: {
      Text("The App Store link has been copied to your clipboard.")
    }
  }

  // MARK: - Share Functions

  func shareViaMessages() {
    let sms =
      "sms:&body=\(shareMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") \(appStoreLink)"
    if let url = URL(string: sms) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }

  func shareViaWhatsApp() {
    let whatsapp =
      "whatsapp://send?text=\(shareMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") \(appStoreLink)"
    if let url = URL(string: whatsapp), UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    } else {
      // Fallback to share sheet if WhatsApp is not installed
      showingShareSheet = true
    }
  }

  func shareViaFacebook() {
    let facebook =
      "fb://publish/profile/me?text=\(shareMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") \(appStoreLink)"
    if let url = URL(string: facebook), UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    } else {
      // Fallback to Facebook web
      if let url = URL(string: "https://www.facebook.com/sharer/sharer.php?u=\(appStoreLink)") {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
  }

  func shareViaTwitter() {
    let text =
      "\(shareMessage) \(appStoreLink)".addingPercentEncoding(
        withAllowedCharacters: .urlQueryAllowed) ?? ""
    let twitter = "twitter://post?message=\(text)"
    if let url = URL(string: twitter), UIApplication.shared.canOpenURL(url) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    } else {
      // Fallback to Twitter web
      if let url = URL(string: "https://twitter.com/intent/tweet?text=\(text)") {
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
      }
    }
  }

  func shareViaInstagram() {
    // Instagram doesn't support direct URL sharing, so we'll copy to clipboard and show instructions
    UIPasteboard.general.string = "\(shareMessage)\n\(appStoreLink)"
    showingShareSheet = true
  }

  func shareViaEmail() {
    let subject =
      "Check out Zen Every Day App".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
      ?? ""
    let body =
      "\(shareMessage)\n\n\(appStoreLink)".addingPercentEncoding(
        withAllowedCharacters: .urlQueryAllowed) ?? ""
    let mailto = "mailto:?subject=\(subject)&body=\(body)"

    if let url = URL(string: mailto) {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }
}

struct SharePlatformButton: View {
  let platform: String
  let icon: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 20))
          .foregroundColor(color)
          .frame(width: 30)

        Text(platform)
          .font(.system(size: 16, weight: .medium))
          .foregroundColor(.primary)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.system(size: 14))
          .foregroundColor(.secondary)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.secondarySystemGroupedBackground))
          .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
      )
    }
  }
}

struct BenefitRow: View {
  let icon: String
  let text: String
  let color: Color

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.system(size: 20))
        .foregroundColor(color)
        .frame(width: 30)

      Text(text)
        .font(.system(size: 15))
        .foregroundColor(.primary)

      Spacer()
    }
    .padding(.vertical, 8)
  }
}

// Share Sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct ShareAppView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationStack {
      ShareAppView()
        .environmentObject(UserSettings())
    }
  }
}
