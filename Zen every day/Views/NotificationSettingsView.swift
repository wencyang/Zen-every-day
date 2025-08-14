import SwiftUI

struct NotificationSettingsView: View {
  @StateObject private var notificationManager = NotificationManager()
  @State private var showingPermissionAlert = false
  @State private var showingTimeSelection = false
  @EnvironmentObject var settings: UserSettings

  var body: some View {
    Form {
      Section(header: Text("Daily Verse Notifications")) {
        Toggle("Enable Notifications", isOn: $notificationManager.isNotificationEnabled)
          .onChange(of: notificationManager.isNotificationEnabled) { oldValue, newValue in
            if newValue {
              // Check if we have permission
              if !notificationManager.hasPermission {
                notificationManager.isNotificationEnabled = false
                // Request permission first
                notificationManager.requestNotificationPermission { granted in
                  if granted {
                    notificationManager.isNotificationEnabled = true
                    showingTimeSelection = true
                    notificationManager.scheduleNotification()
                  } else {
                    // Only show alert if user denied permission
                    showingPermissionAlert = true
                  }
                }
              } else {
                showingTimeSelection = true
                notificationManager.scheduleNotification()
              }
            }
          }

        if notificationManager.isNotificationEnabled {
          HStack {
            Text("Notification Time")
            Spacer()
            Text(timeString(from: notificationManager.notificationTime))
              .foregroundColor(.secondary)
          }
          .contentShape(Rectangle())
          .onTapGesture {
            showingTimeSelection = true
          }
        }
      }

      // The system notification only displays a short snippet, so the app no longer offers a full verse option.

      Section(
        footer: Text(
          "When enabled, you'll receive a daily notification with the verse of the day at your selected time."
        )
      ) {
        EmptyView()
      }
    }
    .navigationTitle("Notifications")
    .navigationBarTitleDisplayMode(.inline)
    .alert("Notification Permission Denied", isPresented: $showingPermissionAlert) {
      Button("Cancel", role: .cancel) {}
      Button("Open Settings") {
        if let url = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(url)
        }
      }
    } message: {
      Text(
        "You denied notification permission. To enable notifications, please go to Settings > Daily Bible > Notifications and turn on 'Allow Notifications'."
      )
    }
    .sheet(isPresented: $showingTimeSelection) {
      TimePickerSheet(notificationManager: notificationManager)
    }
  }

  private func timeString(from date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }
}


struct TimePickerSheet: View {
  @ObservedObject var notificationManager: NotificationManager
  @Environment(\.dismiss) private var dismiss
  @State private var selectedTime: Date

  init(notificationManager: NotificationManager) {
    self.notificationManager = notificationManager
    self._selectedTime = State(initialValue: notificationManager.notificationTime)
  }

  var body: some View {
    NavigationView {
      VStack {
        Text("Choose a time to receive your daily verse")
          .font(.headline)
          .padding()

        DatePicker("Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
          .datePickerStyle(WheelDatePickerStyle())
          .labelsHidden()
          .padding()

        Spacer()
      }
      .navigationTitle("Notification Time")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            notificationManager.notificationTime = selectedTime
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
  }
}

struct NotificationSettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      NotificationSettingsView()
        .environmentObject(UserSettings())
    }
  }
}
