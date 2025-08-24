import SwiftUI
import UIKit

struct SavedQuotesView: View {
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedQuotesManager: SavedQuotesManager
  @State private var showCopyToast = false

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        VStack(spacing: 12) {
          Text("Saved Quotes")
            .font(.title2)
            .fontWeight(.bold)

          if !savedQuotesManager.savedQuotes.isEmpty {
            Text("\(savedQuotesManager.savedQuotes.count) quote\(savedQuotesManager.savedQuotes.count == 1 ? "" : "s") saved")
              .font(.subheadline)
              .foregroundColor(.secondary)
          } else {
            Text("Your saved quotes")
              .font(.subheadline)
              .foregroundColor(.secondary)
          }
        }
        .padding(.top, 20)

        if savedQuotesManager.savedQuotes.isEmpty {
          VStack(spacing: 20) {
            Image(systemName: "bookmark.slash")
              .font(.system(size: 60))
              .foregroundColor(.secondary.opacity(0.5))

            Text("No saved quotes")
              .font(.title3)
              .fontWeight(.medium)
              .foregroundColor(.secondary)

            Text("Save quotes to see them here")
              .font(.subheadline)
              .foregroundColor(.secondary.opacity(0.8))
              .multilineTextAlignment(.center)
              .padding(.horizontal, 40)
          }
          .padding(.vertical, 40)
        } else {
          LazyVStack(spacing: 16) {
            ForEach(savedQuotesManager.savedQuotes.sorted(by: { $0.dateSaved > $1.dateSaved })) { saved in
              SavedQuoteCard(saved: saved, onCopy: { showCopyToast = true })
                .environmentObject(settings)
                .environmentObject(savedQuotesManager)
            }
          }
          .padding(.horizontal)
        }
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
    .toast(
      isShowing: $showCopyToast,
      message: "Quote Copied",
      icon: "doc.on.doc.fill",
      color: .green,
      duration: 1.2
    )
    .onAppear {
      savedQuotesManager.updateMissingBackgrounds()
    }
  }
}

struct SavedQuoteCard: View {
  let saved: SavedQuote
  let onCopy: () -> Void
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedQuotesManager: SavedQuotesManager
  @State private var isExpanded = false

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(formattedDate(saved.dateSaved))
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.secondary)

          if let author = saved.author {
            Text(author)
              .font(.system(size: 13))
              .foregroundColor(.secondary)
          }
        }

        Spacer()

        HStack(spacing: 16) {
          Button(action: {
            savedQuotesManager.removeSavedQuote(saved)
          }) {
            Image(systemName: "bookmark.slash")
              .font(.system(size: 18))
              .foregroundColor(.red)
          }
          .buttonStyle(PlainButtonStyle())

          Button(action: {
            savedQuotesManager.copySavedQuote(saved)
            onCopy()
          }) {
            Image(systemName: "doc.on.doc")
              .font(.system(size: 18))
              .foregroundColor(.blue)
          }
          .buttonStyle(PlainButtonStyle())

          Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
              isExpanded.toggle()
            }
          }) {
            Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
              .font(.system(size: 20))
              .foregroundColor(.blue)
          }
          .buttonStyle(PlainButtonStyle())
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)

      VStack(alignment: .leading, spacing: 12) {
        if isExpanded {
          Divider()
            .padding(.horizontal, 16)

          Text(saved.text)
            .font(.system(size: settings.fontSize))
            .foregroundColor(.primary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .transition(
              .asymmetric(
                insertion: .scale(scale: 0.95).combined(with: .opacity),
                removal: .scale(scale: 0.95).combined(with: .opacity)
              )
            )
        } else {
          Text(saved.text)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
            .lineLimit(2)
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
      }
    }
    .background(
      SavedQuoteBackgroundView(photoName: saved.backgroundPhotoName)
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(
          LinearGradient(
            gradient: Gradient(colors: [
              Color.blue.opacity(0.2),
              Color.purple.opacity(0.1),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          ),
          lineWidth: 1
        )
    )
    .contentShape(Rectangle())
    .onTapGesture {
      withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
        isExpanded.toggle()
      }
    }
  }

  private func formattedDate(_ date: Date) -> String {
    let calendar = Calendar.current

    if calendar.isDateInToday(date) {
      return "Today"
    } else if calendar.isDateInYesterday(date) {
      return "Yesterday"
    } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
      let dayFormatter = DateFormatter()
      dayFormatter.dateFormat = "EEEE"
      return dayFormatter.string(from: date)
    } else {
      let displayFormatter = DateFormatter()
      displayFormatter.dateStyle = .medium
      return displayFormatter.string(from: date)
    }
  }
}

struct SavedQuoteBackgroundView: View {
  let photoName: String?

  var body: some View {
    Group {
      if let name = photoName {
        if let image = UIImage(named: name) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .overlay(Color.black.opacity(0.2))
        } else if let dataAsset = NSDataAsset(name: name), let image = UIImage(data: dataAsset.data) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .overlay(Color.black.opacity(0.2))
        } else {
          Color(.secondarySystemGroupedBackground)
        }
      } else {
        Color(.secondarySystemGroupedBackground)
      }
    }
  }
}
