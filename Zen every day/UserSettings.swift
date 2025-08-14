import SwiftUI

class UserSettings: ObservableObject {
  @Published var fontSize: Double {
    didSet {
      UserDefaults.standard.set(fontSize, forKey: "fontSize")
    }
  }

  init() {
    let stored = UserDefaults.standard.double(forKey: "fontSize")
    self.fontSize = stored == 0 ? 16 : stored
  }
}
