import SwiftUI

struct SettingsView: View {
  var body: some View {
    Form {
      Section(header: Text("Appearance")) {
        NavigationLink("Appearance Settings") {
          AppearanceSettingsView()
        }
      }

      Section(header: Text("Audio")) {
        NavigationLink("Audio Settings") {
          AudioSettingsView()
        }
      }

      Section(header: Text("Notifications")) {
        NavigationLink("Notification Settings") {
          NotificationSettingsView()
        }
      }
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct AppearanceSettingsView: View {
  @AppStorage("appearanceMode") var appearanceMode: String = "system"
  /// When `true`, the background will change daily instead of every launch.
  @AppStorage("disableBackgroundChangeEachLaunch") private var disableChangeEachLaunch: Bool = false

  var body: some View {
    Form {
      Section(header: Text("Appearance Mode")) {
        Picker("Appearance Mode", selection: $appearanceMode) {
          Text("System").tag("system")
          Text("Light").tag("light")
          Text("Dark").tag("dark")
        }
        .pickerStyle(SegmentedPickerStyle())
      }

      Section(header: Text("FONT")) {
        NavigationLink("Font Settings") {
          FontSettingsView()
        }
      }

      Section(header: Text("Background")) {
        Toggle("Don't change background on every launch", isOn: $disableChangeEachLaunch)
      }
    }
    .navigationTitle("Appearance")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct AudioSettingsView: View {
  @AppStorage("autoPlayMusic") private var autoPlayMusic: Bool = true
  @AppStorage("musicVolume") private var musicVolume: Double = 0.5

  var body: some View {
    Form {
      Section(
        header: Text("Background Music"),
        footer: Text(
          "Control the ambient music that plays on the Daily Verse screen. You can always manually play or pause music using the play button."
        )
      ) {
        Toggle("Auto-play music on launch", isOn: $autoPlayMusic)
          .tint(.blue)

        if autoPlayMusic {
          VStack(alignment: .leading, spacing: 8) {
            HStack {
              Text("Volume")
              Spacer()
              Text("\(Int(musicVolume * 100))%")
                .foregroundColor(.secondary)
                .font(.caption)
            }

            Slider(value: $musicVolume, in: 0...1)
              .tint(.blue)
          }
          .padding(.vertical, 4)
        }
      }

      Section(
        header: Text("About Audio"),
        footer: Text(
          "The background music is designed to enhance your spiritual experience while reading daily verses. All audio content is original and created specifically for Daily Bible."
        )
      ) {
        HStack {
          Image(systemName: "music.note")
            .foregroundColor(.blue)

          VStack(alignment: .leading, spacing: 2) {
            Text("Peaceful Instrumental")
              .font(.subheadline)
              .fontWeight(.medium)

            Text("Ambient spiritual music")
              .font(.caption)
              .foregroundColor(.secondary)
          }

          Spacer()
        }
        .padding(.vertical, 4)
      }
    }
    .navigationTitle("Audio Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct FontSettingsView: View {
  @EnvironmentObject var settings: UserSettings

  var body: some View {
    Form {
      Section(header: Text("Font Size")) {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            Text("Size: \(Int(settings.fontSize))")
              .font(.system(size: 14))
              .foregroundColor(.secondary)
            Spacer()
          }

          Slider(value: $settings.fontSize, in: 10...30, step: 1)

          VStack(alignment: .leading, spacing: 8) {
            Text("Preview:")
              .font(.caption)
              .foregroundColor(.secondary)
            Text("The quick brown fox jumps over the lazy dog.")
              .font(.system(size: settings.fontSize))
              .padding()
              .background(Color(.systemGray6))
              .cornerRadius(8)
          }
        }
        .padding(.vertical, 8)
      }
    }
    .navigationTitle("Font Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      SettingsView()
    }
    .environmentObject(UserSettings())
  }
}
