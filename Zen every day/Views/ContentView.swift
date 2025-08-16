import SwiftUI

struct ContentView: View {
  @EnvironmentObject var settings: UserSettings
  @EnvironmentObject var musicManager: BackgroundMusicManager
  @EnvironmentObject var backgroundManager: BackgroundImageManager
  @EnvironmentObject var savedQuotesManager: SavedQuotesManager
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass
  @StateObject var dailyWisdomManager = DailyWisdomManager()

  @State private var selectedTab = 0  // 0: Daily Quote, 1: Search, 2: Study, 3: More
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
              if let quote = dailyWisdomManager.dailyQuote {
                VStack(spacing: 12) {
                  Text(quote.text)
                    .font(.system(size: settings.fontSize, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color.black.opacity(0.5).cornerRadius(10))

                  if let author = quote.author {
                    Text(author)
                      .font(.system(size: settings.fontSize * 0.9))
                      .foregroundColor(.white)
                  }

                  Button(action: {
                    savedQuotesManager.toggleQuoteSaved(quote)
                  }) {
                    Image(systemName: savedQuotesManager.isQuoteSaved(quote) ? "bookmark.fill" : "bookmark")
                      .font(.title2)
                      .foregroundColor(.white)
                      .padding(8)
                      .background(Color.black.opacity(0.5).clipShape(Circle()))
                  }
                }
                .padding(.horizontal)
              } else if let error = dailyWisdomManager.errorMessage {
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
          Label("Daily Wisdom", systemImage: "house.fill")
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

      // 3) Study Tab

      NavigationStack {
        StudyView()
      }
      .tabItem {
        Label("Study", systemImage: "book.fill")
      }
      .tag(2)

      // 4) More Tab
      NavigationView {
        MoreView()
      }
      .tabItem {
        Label("More", systemImage: "ellipsis.circle.fill")
      }
      .tag(3)
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
      isShowing: $savedQuotesManager.showSavedToast,
      message: "Quote Saved",
      icon: "bookmark.fill",
      color: .blue
    )
    .toast(
      isShowing: $savedQuotesManager.showRemovedToast,
      message: "Bookmark Removed",
      icon: "bookmark.slash.fill",
      color: .red
    )
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
      .environmentObject(BackgroundImageManager())
  }
}
