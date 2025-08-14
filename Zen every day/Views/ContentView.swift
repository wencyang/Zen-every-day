import SwiftUI

struct ContentView: View {
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var savedVersesManager: SavedVersesManager
  @EnvironmentObject var musicManager: BackgroundMusicManager
  @EnvironmentObject var backgroundManager: BackgroundImageManager
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @StateObject var dailyVerseManager = DailyVerseManager()

  @State private var searchQuery = ""
  @State private var showingCardCreator = false  // New state for verse sharing

  @State private var selectedTab = 0  // 0: Daily Verse, 1: Search, 2: Bible Study, 3: Topics, 4: More
  @AppStorage("musicVolume") private var musicVolume: Double = 0.5


  init() {
    // Make tab bar transparent with glass effect
    let appearance = UITabBarAppearance()
    appearance.configureWithTransparentBackground()

    // Remove any background color to achieve true transparency
    appearance.backgroundColor = .clear
    appearance.backgroundImage = UIImage()
    appearance.shadowImage = UIImage()
    appearance.shadowColor = .clear

    // Set blur effect for glass appearance
    appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)

    // Configure tab item appearance for better visibility
    appearance.stackedLayoutAppearance.normal.iconColor = UIColor.label.withAlphaComponent(0.7)
    appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
      NSAttributedString.Key.foregroundColor: UIColor.label.withAlphaComponent(0.7)
    ]

    appearance.stackedLayoutAppearance.selected.iconColor = UIColor.systemBlue
    appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
      NSAttributedString.Key.foregroundColor: UIColor.systemBlue
    ]

    // Apply to all tab bar states
    UITabBar.appearance().standardAppearance = appearance
    UITabBar.appearance().scrollEdgeAppearance = appearance
    if #available(iOS 15.0, *) {
      UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // Additional settings for transparency
    UITabBar.appearance().isTranslucent = true
    UITabBar.appearance().backgroundImage = UIImage()
    UITabBar.appearance().shadowImage = UIImage()
  }

  var body: some View {
    TabView(selection: $selectedTab) {
      // 1) Daily Verse Tab
      NavigationView {
        ZStack {
          Image(backgroundManager.currentPhotoName)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()  // This will make it go behind the tab bar

          VStack {
            Spacer()

            ScrollView {
              if let verse = dailyVerseManager.dailyVerse {
                VStack(spacing: 12) {
                  Text("\(verse.text.cleanVerse)")
                    .font(.system(size: settings.fontSize, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.5).cornerRadius(10))

                  HStack(spacing: 16) {
                    Text("\(verse.book_name) \(verse.chapter):\(verse.verse)")
                      .font(.system(size: settings.fontSize * 0.9))
                      .foregroundColor(.white)

                    HStack(spacing: 12) {
                      // Share button - Fixed sizing
                      Button(action: {
                        showingCardCreator = true
                      }) {
                        Image(systemName: "square.and.arrow.up")
                          .font(.system(size: 16, weight: .medium))
                          .foregroundColor(.white)
                          .frame(width: 20, height: 20)
                          .padding(10)
                          .background(Color.white.opacity(0.2))
                          .clipShape(Circle())
                      }

                      // Bookmark button - Fixed sizing to match share button
                      Button(action: {
                        savedVersesManager.toggleVerseSaved(verse)
                      }) {
                        Image(
                          systemName: savedVersesManager.isVerseSaved(verse)
                            ? "bookmark.fill" : "bookmark"
                        )
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                      }
                    }
                  }
                }
                .padding(.horizontal)
              } else if let error = dailyVerseManager.errorMessage {
                Text(error)
                  .foregroundColor(.red)
                  .padding()
                  .background(Color.black.opacity(0.5).cornerRadius(10))
              } else {
                VStack(spacing: 12) {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)

                  Text("Loading")
                    .foregroundColor(.white)
                    .font(.subheadline)
                }
                .padding(16)
                .background(Color.black.opacity(0.5))
                .cornerRadius(10)
              }
            }
            .frame(
              maxWidth: horizontalSizeClass == .regular ? 600 : 400,
              maxHeight: .infinity
            )

            // Audio control button with custom styling
            MusicControlButton(isPlaying: musicManager.isPlaying, action: musicManager.toggleAudio)
              .padding(.bottom, 100) // Add padding to account for tab bar height

            Spacer()
          }
          .padding()
        }
        .navigationTitle("")
        .navigationBarHidden(true)
      }
      .tabItem {
        Label("Daily Verse", systemImage: "house.fill")
      }
      .tag(0)

      // 2) Search Tab
      NavigationView {
        SearchView()
      }
      .tabItem {
        Label("Search", systemImage: "magnifyingglass")
      }
      .tag(1)

      // 3) Bible Study Tab

      NavigationStack {
        CombinedBibleStudyView()
      }
      .tabItem {
        Label("Bible Study", systemImage: "book.fill")
      }
      .tag(2)

      NavigationView {
        ReadingPlansView()  // NEW
      }
      .tabItem {
        Label("Reading Plans", systemImage: "book.circle")  // Updated
      }
      .tag(3)

      // 5) More Tab
      NavigationView {
        MoreView()
      }
      .tabItem {
        Label("More", systemImage: "ellipsis.circle.fill")
      }
      .tag(4)
    }
    .navigationViewStyle(.stack)
    .onAppear {
      showRandomPhoto()
      musicManager.startIfNeeded()
    }
    .onChange(of: musicVolume) { _ , _ in
      musicManager.updateVolume()
    }
    .toast(
      isShowing: $savedVersesManager.showSavedToast,
      message: "Saved to Bookmarks",
      icon: "bookmark.fill",
      color: .blue,
      duration: 1.2
    )
    .toast(
      isShowing: $savedVersesManager.showRemovedToast,
      message: "Removed from Bookmarks",
      icon: "bookmark.slash.fill",
      color: .orange,
      duration: 1.2
    )
    // Sheet for verse card creator - NEW
    .sheet(isPresented: $showingCardCreator) {
      if let verse = dailyVerseManager.dailyVerse {
        VerseCardCreator(verse: verse)
      }
    }
  }

  // MARK: - Helper Methods

  func showRandomPhoto() {
    backgroundManager.randomizePhotoIfNeeded()
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
      .environmentObject(UserSettings())
      .environmentObject(SavedVersesManager())
      .environmentObject(BackgroundImageManager())
  }
}
