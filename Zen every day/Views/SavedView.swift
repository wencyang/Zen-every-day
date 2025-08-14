import SwiftUI

struct SavedView: View {
  @EnvironmentObject var savedVersesManager: SavedVersesManager
  @EnvironmentObject var settings: UserSettings
  @State private var showingDeleteAlert = false
  @State private var verseToDelete: SavedVerse?
  @State private var verseToEdit: SavedVerse?
  @State private var commentText: String = ""
  @State private var showingCommentSheet = false
  @State private var showOnlyFavorites = false
  @State private var showingDeleteNoteAlert = false
  @State private var verseToDeleteNote: SavedVerse?

  // New states for verse sharing
  @State private var selectedVerseForCard: Verse?
  @State private var showCopyToast = false

  var body: some View {
    VStack(spacing: 0) {
      // Header with filter toggle
      VStack(spacing: 16) {
        // Title and subtitle
        VStack(spacing: 4) {
          Text("Saved Verses")
            .font(.title2)
            .fontWeight(.bold)

          Text("\(filteredVerses.count) verse\(filteredVerses.count == 1 ? "" : "s") saved")
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding(.top)

        // Filter toggle with better design
        HStack {
          Label("Favorites Only", systemImage: showOnlyFavorites ? "heart.fill" : "heart")
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(showOnlyFavorites ? .red : .primary)

          Spacer()

          Toggle("", isOn: $showOnlyFavorites)
            .labelsHidden()
            .tint(.red)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemGray6))
        )
        .padding(.horizontal)
      }
      .background(Color(.systemGroupedBackground))

      // Content
      if filteredVerses.isEmpty {
        // Empty state
        VStack(spacing: 20) {
          Spacer()

          Image(systemName: showOnlyFavorites ? "heart.slash" : "bookmark.slash")
            .font(.system(size: 60))
            .foregroundColor(.secondary)

          Text(showOnlyFavorites ? "No favorite verses" : "No saved verses")
            .font(.title2)
            .fontWeight(.semibold)

          Text(
            showOnlyFavorites
              ? "Tap the heart icon on saved verses to mark them as favorites"
              : "Save verses while reading to see them here"
          )
          .font(.system(size: settings.fontSize * 0.9))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)

          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
      } else {
        // Verses list
        List {
          ForEach(filteredVerses.sorted(by: { $0.dateSaved > $1.dateSaved })) { savedVerse in
            VerseCard(
              savedVerse: savedVerse,
              showCopyToast: $showCopyToast,
              onToggleFavorite: {
                savedVersesManager.toggleFavorite(for: savedVerse)
              },
              onEditNote: {
                verseToEdit = savedVerse
                commentText = savedVerse.comment ?? ""
                showingCommentSheet = true
              },
              onDeleteNote: {
                verseToDeleteNote = savedVerse
                showingDeleteNoteAlert = true
              },
              onShare: { verse in
                selectedVerseForCard = verse
              }
            )
            .environmentObject(settings)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
              Button(role: .destructive) {
                verseToDelete = savedVerse
                showingDeleteAlert = true
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
    .alert("Delete Saved Verse?", isPresented: $showingDeleteAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let verse = verseToDelete {
          withAnimation {
            savedVersesManager.removeSavedVerse(verse)
          }
        }
      }
    } message: {
      Text("This verse will be removed from your saved collection.")
    }
    .alert("Delete Note?", isPresented: $showingDeleteNoteAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive) {
        if let verse = verseToDeleteNote {
          savedVersesManager.updateComment(for: verse, newComment: "")
        }
      }
    } message: {
      Text("This will permanently delete your note for this verse.")
    }
    .sheet(isPresented: $showingCommentSheet) {
      NoteEditorSheet(
        commentText: $commentText,
        verse: verseToEdit,
        onSave: {
          if let verse = verseToEdit {
            savedVersesManager.updateComment(for: verse, newComment: commentText)
          }
        }
      )
    }
    .toast(
      isShowing: $showCopyToast,
      message: "Verse Copied",
      icon: "doc.on.doc.fill",
      color: .green,
      duration: 1.2
    )
    .sheet(item: $selectedVerseForCard) { verse in
      VerseCardCreator(verse: verse)
    }
  }

  private var filteredVerses: [SavedVerse] {
    showOnlyFavorites
      ? savedVersesManager.savedVerses.filter { $0.isFavorite }
      : savedVersesManager.savedVerses
  }
}

// Updated VerseCard component with share functionality
struct VerseCard: View {
  let savedVerse: SavedVerse
  @Binding var showCopyToast: Bool
  let onToggleFavorite: () -> Void
  let onEditNote: () -> Void
  let onDeleteNote: () -> Void
  let onShare: (Verse) -> Void  // New callback
  @EnvironmentObject var settings: UserSettings
  @State private var isNoteExpanded = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header with reference and actions
      HStack(alignment: .center) {
        // Reference
        Text("\(savedVerse.book_name) \(savedVerse.chapter):\(savedVerse.verse)")
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(.blue)

        Spacer()

        // Date
        Text(formattedDate(savedVerse.dateSaved))
          .font(.caption)
          .foregroundColor(.secondary)

        // Action buttons
        HStack(spacing: 8) {
          // Share button - NEW
          Button(action: {
            let verse = Verse(
              book_name: savedVerse.book_name,
              book: 1,  // Default value
              chapter: savedVerse.chapter,
              verse: savedVerse.verse,
              text: savedVerse.text
            )
            onShare(verse)
          }) {
            Image(systemName: "square.and.arrow.up")
              .font(.system(size: 18))
              .foregroundColor(.blue)
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .frame(width: 44, height: 44)

          // Copy button
          Button(action: {
            let copyText = "\(savedVerse.text)\n\(savedVerse.book_name) \(savedVerse.chapter):\(savedVerse.verse)"
            UIPasteboard.general.string = copyText
            showCopyToast = true
          }) {
            Image(systemName: "doc.on.doc")
              .font(.system(size: 18))
              .foregroundColor(.blue)
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .frame(width: 44, height: 44)

          // Favorite button
          Button(action: onToggleFavorite) {
            Image(systemName: savedVerse.isFavorite ? "heart.fill" : "heart")
              .font(.system(size: 18))
              .foregroundColor(savedVerse.isFavorite ? .red : .gray)
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .frame(width: 44, height: 44)
        }
      }

      // Verse text
      Text(savedVerse.text)
        .font(.system(size: settings.fontSize))
        .fixedSize(horizontal: false, vertical: true)

      // Note preview if exists
      if let comment = savedVerse.comment, !comment.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          HStack(alignment: .top, spacing: 8) {
            Image(systemName: "note.text")
              .font(.system(size: 12))
              .foregroundColor(.secondary)
              .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
              // Note text with expand/collapse functionality
              VStack(alignment: .leading, spacing: 4) {
                Text(comment)
                  .font(.system(size: 14))
                  .foregroundColor(.secondary)
                  .lineLimit(isNoteExpanded ? nil : 3)
                  .fixedSize(horizontal: false, vertical: true)

                // Show more/less button if note is long
                if comment.count > 150 || comment.components(separatedBy: .newlines).count > 3 {
                  Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                      isNoteExpanded.toggle()
                    }
                  }) {
                    Text(isNoteExpanded ? "Show less" : "Show more")
                      .font(.system(size: 12, weight: .medium))
                      .foregroundColor(.blue)
                  }
                  .buttonStyle(PlainButtonStyle())
                }
              }

              // Note action buttons
              HStack(spacing: 12) {
                Button(action: onEditNote) {
                  HStack(spacing: 4) {
                    Image(systemName: "pencil")
                      .font(.system(size: 12))
                    Text("Edit")
                      .font(.system(size: 12, weight: .medium))
                  }
                  .foregroundColor(.blue)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(
                    RoundedRectangle(cornerRadius: 6)
                      .stroke(Color.blue, lineWidth: 1)
                  )
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: onDeleteNote) {
                  HStack(spacing: 4) {
                    Image(systemName: "trash")
                      .font(.system(size: 12))
                    Text("Delete")
                      .font(.system(size: 12, weight: .medium))
                  }
                  .foregroundColor(.red)
                  .padding(.horizontal, 8)
                  .padding(.vertical, 4)
                  .background(
                    RoundedRectangle(cornerRadius: 6)
                      .stroke(Color.red, lineWidth: 1)
                  )
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()
              }
            }
          }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
          RoundedRectangle(cornerRadius: 8)
            .fill(Color(.tertiarySystemGroupedBackground))
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color.primary.opacity(0.1), lineWidth: 0.5)
            )
        )
      } else {
        // Add Note button when no note exists
        Button(action: onEditNote) {
          HStack {
            Image(systemName: "note.text.badge.plus")
              .font(.system(size: 14))

            Text("Add Note")
              .font(.system(size: 14, weight: .medium))
          }
          .foregroundColor(.blue)
          .padding(.horizontal, 16)
          .padding(.vertical, 8)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .stroke(Color.blue, lineWidth: 1)
          )
        }
        .buttonStyle(PlainButtonStyle())
      }
    }
    .padding()
    .background(
      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.secondarySystemGroupedBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    )
  }

  private func formattedDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
  }
}

// Keep the existing NoteEditorSheet component as is
struct NoteEditorSheet: View {
  @Binding var commentText: String
  let verse: SavedVerse?
  let onSave: () -> Void
  @Environment(\.dismiss) private var dismiss
  @FocusState private var isTextEditorFocused: Bool

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Verse preview
        if let verse = verse {
          VStack(alignment: .leading, spacing: 8) {
            Text("\(verse.book_name) \(verse.chapter):\(verse.verse)")
              .font(.caption)
              .foregroundColor(.secondary)

            Text(verse.text)
              .font(.system(size: 16))
              .lineLimit(3)
          }
          .padding()
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color(.systemGray6))
        }

        // Note editor
        VStack(alignment: .leading, spacing: 8) {
          Text("Your Note")
            .font(.headline)
            .padding(.horizontal)
            .padding(.top)

          TextEditor(text: $commentText)
            .padding(8)
            .overlay(
              RoundedRectangle(cornerRadius: 8)
                .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.horizontal)
            .focused($isTextEditorFocused)
        }

        Spacer()
      }
      .navigationTitle("Edit Note")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            onSave()
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
    .onAppear {
      isTextEditorFocused = true
    }
  }
}

struct SavedView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      SavedView()
        .environmentObject(SavedVersesManager())
        .environmentObject(UserSettings())
    }
  }
}
