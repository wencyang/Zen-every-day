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

              HStack {
                Spacer()
                Button(action: {
                  var copyText = saved.text
                  if let author = saved.author {
                    copyText += "\n- \(author)"
                  }
                  UIPasteboard.general.string = copyText
                  showCopyToast = true
                }) {
                  Image(systemName: "doc.on.doc")
                    .font(.system(size: 16))
                    .foregroundColor(.blue)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }
            .padding(.vertical, 4)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
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
    .toast(
      isShowing: $savedQuotesManager.showRemovedToast,
      message: "Bookmark Removed",
      icon: "bookmark.slash.fill",
      color: .red
    )
  }
}

