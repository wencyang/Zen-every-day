import Combine
import SwiftUI

// MARK: - Toast Notification System

// Toast notification view
struct ToastView: View {
  let message: String
  let icon: String
  let color: Color
  @Binding var isShowing: Bool

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(color)

      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.primary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(
      Capsule()
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
    .scaleEffect(isShowing ? 1.0 : 0.8)
    .opacity(isShowing ? 1.0 : 0.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
  }
}

// Toast notification modifier
struct ToastModifier: ViewModifier {
  @Binding var isShowing: Bool
  let message: String
  let icon: String
  let color: Color
  let duration: Double

  func body(content: Content) -> some View {
    ZStack {
      content

      if isShowing {
        VStack {
          Spacer()

          ToastView(
            message: message,
            icon: icon,
            color: color,
            isShowing: $isShowing
          )
          .padding(.bottom, 100)  // Account for tab bar

          Spacer()
        }
        .allowsHitTesting(false)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .onChange(of: isShowing) { oldValue, newValue in
      if newValue {
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
          withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
          }
        }
      }
    }
  }
}

// Convenient extension for easy use
extension View {
  func toast(
    isShowing: Binding<Bool>,
    message: String,
    icon: String = "checkmark.circle.fill",
    color: Color = .green,
    duration: Double = 1.5
  ) -> some View {
    self.modifier(
      ToastModifier(
        isShowing: isShowing,
        message: message,
        icon: icon,
        color: color,
        duration: duration
      )
    )
  }
}

// MARK: - Saved Verse Model

// Model for saved verses
struct SavedVerse: Codable, Identifiable {
  var id: String { "\(book_name)_\(chapter)_\(verse)" }
  let book_name: String
  let chapter: Int
  let verse: Int
  let text: String
  let dateSaved: Date
  var comment: String?
  var isFavorite: Bool = false
}

// MARK: - Enhanced SavedVersesManager

class SavedVersesManager: ObservableObject {
  @Published var savedVerses: [SavedVerse] = []
  @Published var showSavedToast = false
  @Published var showRemovedToast = false

  private let savedVersesKey = "savedBibleVerses"
  private var cancellables = Set<AnyCancellable>()
  private var savedIDs: Set<String> = []

  init() {
    loadSavedVerses()
  }

  func loadSavedVerses() {
    if let data = UserDefaults.standard.data(forKey: savedVersesKey),
      let decoded = try? JSONDecoder().decode([SavedVerse].self, from: data)
    {
      savedVerses = decoded
      savedIDs = Set(decoded.map { $0.id })
    }
  }

  func saveVerse(_ verse: Verse) {
    // Check if verse is already saved
    if !isVerseSaved(verse) {
      let savedVerse = SavedVerse(
        book_name: verse.book_name,
        chapter: verse.chapter,
        verse: verse.verse,
        text: verse.text.cleanVerse,
        dateSaved: Date()
      )

      // Update without triggering immediate view updates
      objectWillChange.send()
      savedVerses.append(savedVerse)
      savedIDs.insert(savedVerse.id)

      // Show toast notification with haptic feedback
      DispatchQueue.main.async {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          self.showSavedToast = true
        }
      }

      // Persist after a delay to batch updates
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.persistSavedVerses()
      }
    }
  }

  func removeVerse(_ verse: Verse) {
    if isVerseSaved(verse) {
      objectWillChange.send()
      savedVerses.removeAll { savedVerse in
        savedVerse.book_name == verse.book_name && savedVerse.chapter == verse.chapter
          && savedVerse.verse == verse.verse
      }
      savedIDs.remove("\(verse.book_name)_\(verse.chapter)_\(verse.verse)")

      // Show toast notification with haptic feedback
      DispatchQueue.main.async {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
          self.showRemovedToast = true
        }
      }

      // Persist after a delay to batch updates
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
        self?.persistSavedVerses()
      }
    }
  }

  func removeSavedVerse(_ savedVerse: SavedVerse) {
    savedVerses.removeAll { $0.id == savedVerse.id }
    savedIDs.remove(savedVerse.id)
    persistSavedVerses()
  }

  func isVerseSaved(_ verse: Verse) -> Bool {
    savedIDs.contains("\(verse.book_name)_\(verse.chapter)_\(verse.verse)")
  }

  func toggleVerseSaved(_ verse: Verse) {
    if isVerseSaved(verse) {
      removeVerse(verse)
    } else {
      saveVerse(verse)
    }
  }

  private func persistSavedVerses() {
    if let encoded = try? JSONEncoder().encode(savedVerses) {
      UserDefaults.standard.set(encoded, forKey: savedVersesKey)
    }
  }

  func updateComment(for verse: SavedVerse, newComment: String) {
    if let index = savedVerses.firstIndex(where: { $0.id == verse.id }) {
      savedVerses[index].comment = newComment.isEmpty ? nil : newComment
      persistSavedVerses()
    }
  }

  func toggleFavorite(for verse: SavedVerse) {
    if let index = savedVerses.firstIndex(where: { $0.id == verse.id }) {
      savedVerses[index].isFavorite.toggle()
      persistSavedVerses()
    }
  }
}
