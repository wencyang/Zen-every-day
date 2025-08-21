import SwiftUI
import UIKit

struct SavedQuotesView: View {
  @EnvironmentObject var savedQuotesManager: SavedQuotesManager
  @State private var showCopyToast = false

  var body: some View {
    VStack(spacing: 0) {
      VStack(spacing: 4) {
        Text("Saved Quotes")
          .font(.title2)
          .fontWeight(.bold)

        Text("\(savedQuotesManager.savedQuotes.count) quote\(savedQuotesManager.savedQuotes.count == 1 ? "" : "s") saved")
          .font(.subheadline)
          .foregroundColor(.secondary)
      }
      .padding(.top)

      if savedQuotesManager.savedQuotes.isEmpty {
        Spacer()

        Image(systemName: "bookmark.slash")
          .font(.system(size: 60))
          .foregroundColor(.secondary)

        Text("No saved quotes")
          .font(.title2)
          .fontWeight(.semibold)

        Text("Save quotes to see them here")
          .font(.system(size: 16))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)

        Spacer()
      } else {
        List {
          ForEach(savedQuotesManager.savedQuotes.sorted(by: { $0.dateSaved > $1.dateSaved })) { saved in
            VStack(alignment: .leading, spacing: 8) {
              Text(saved.text)
                .font(.system(size: 16))
                .fixedSize(horizontal: false, vertical: true)

              if let author = saved.author {
                Text(author)
                  .font(.caption)
                  .foregroundColor(.secondary)
              }

              HStack(spacing: 12) {
                Spacer()
                Button(action: {
                  savedQuotesManager.removeSavedQuote(saved)
                }) {
                  Image(systemName: "bookmark.slash")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                  savedQuotesManager.copySavedQuote(saved)
                  showCopyToast = true
                }) {
                  Image(systemName: "doc.on.doc")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding()
            .listRowBackground(
              SavedQuoteBackgroundView(photoName: saved.backgroundPhotoName)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .contextMenu {
              Button {
                savedQuotesManager.copySavedQuote(saved)
                showCopyToast = true
              } label: {
                Label("Copy", systemImage: "doc.on.doc")
              }
              Button(role: .destructive) {
                savedQuotesManager.removeSavedQuote(saved)
              } label: {
                Label("Delete", systemImage: "trash")
              }
            }
          }
        }
        .listStyle(PlainListStyle())
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
      }
    }
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
