//
//  ZenEveryDayApp.swift
//  Zen Every Day
//
//  Created by Wencao Yang on 1/21/25.
//

import SwiftUI

@main
struct ZenEveryDayApp: App {
  @AppStorage("appearanceMode") var appearanceMode: String = "system"
  @StateObject var settings = UserSettings()
  @StateObject var activityManager = ReadingActivityManager()
  @StateObject var savedQuotesManager = SavedQuotesManager()
  @StateObject var notificationManager = NotificationManager()
  @StateObject var backgroundManager = BackgroundImageManager()
  @StateObject var musicManager = BackgroundMusicManager.shared
  @StateObject var dailyWisdomManager = DailyWisdomManager() // Added this
  @State private var isAppReady = false

  var body: some Scene {
      WindowGroup(content: {
          Group {
              if isAppReady {
                  ContentView()
              } else {
                  AppLoadingView()
              }
          }
          .environmentObject(settings)
          .environmentObject(activityManager)
          .environmentObject(savedQuotesManager)
          .environmentObject(notificationManager)
          .environmentObject(backgroundManager)
          .environmentObject(musicManager)
          .environmentObject(dailyWisdomManager) // Added this
          .preferredColorScheme(colorScheme(for: appearanceMode))
          .onAppear {
              notificationManager.checkNotificationPermission()
              // Schedule notifications if enabled
              if notificationManager.isNotificationEnabled && notificationManager.hasPermission {
                  notificationManager.scheduleNotification()
              }
              prepareApp()
          }
          .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
          ) { _ in
              // Refresh notifications when app comes to foreground
              if notificationManager.isNotificationEnabled && notificationManager.hasPermission {
                  notificationManager.scheduleNotification()
              }
              // Start tracking session
              activityManager.appDidBecomeActive()
          }
          .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
          ) { _ in
              // Save session when app goes to background
              activityManager.appWillResignActive()
          }
          .onReceive(
            NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
          ) { _ in
              // Start tracking when app becomes active
              activityManager.appDidBecomeActive()
          }
      })
  }

  func colorScheme(for mode: String) -> ColorScheme? {
    switch mode {
    case "light":
      return .light
    case "dark":
      return .dark
    default:
      return nil  // Follow system setting
    }
  }

  func prepareApp() {
    // Kick off heavy loading tasks in the background and show the interface
    WisdomManager.shared.loadWisdomIfNeeded()
    
    // Connect the managers so SavedQuotesManager can access DailyWisdomManager's background
    savedQuotesManager.setDailyWisdomManager(dailyWisdomManager)
    print("🔗 Connected DailyWisdomManager to SavedQuotesManager")
    
    isAppReady = true
  }
}
