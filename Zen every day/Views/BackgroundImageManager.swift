import SwiftUI

/// Controls whether the background should change on each app launch.
/// When `true`, the background will only change once per day.

class BackgroundImageManager: ObservableObject {
    /// Indicates whether a background image should be displayed.
    @Published var showBackground: Bool = true

    /// The name of the current photo in the asset catalog.
    @Published var currentPhotoName: String = "photo1"

    /// Provides a `UIImage` for the current photo, if available.
    var currentBackgroundImage: UIImage? {
        // Explicitly load assets from the main bundle to ensure resources are
        // found when rendering quote cards outside of the regular view
        // hierarchy (e.g. when saving to Photos).
        if let image = UIImage(named: currentPhotoName, in: .main, with: nil) {
            return image
        } else if let dataAsset = NSDataAsset(name: currentPhotoName, bundle: .main) {
            return UIImage(data: dataAsset.data)
        }
        return nil
    }

    private let photoNames: [String]

    @AppStorage("backgroundPhotoName") private var storedPhotoName: String = "photo1"
    /// When `true`, the background will change daily instead of every launch.
    @AppStorage("disableBackgroundChangeEachLaunch") private var disableChangeEachLaunch: Bool = false
    @AppStorage("lastRandomizationTimestamp") private var lastRandomizationTimestamp: Double = 0

    init() {
        var names: [String] = []
        var index = 1
        while index <= 1000 {
            let name = "photo\(index)"
            // Look up images explicitly in the main bundle so that all assets
            // used for card generation are discovered correctly.
            if UIImage(named: name, in: .main, with: nil) != nil ||
                NSDataAsset(name: name, bundle: .main) != nil {
                names.append(name)
                index += 1
            } else {
                break
            }
        }
        self.photoNames = names.isEmpty ? ["photo1"] : names
        // Load previously selected photo if available and ensure it's persisted
        if names.contains(storedPhotoName) {
            self.currentPhotoName = storedPhotoName
        } else {
            self.currentPhotoName = self.photoNames.first ?? "photo1"
        }
        storedPhotoName = self.currentPhotoName
    }

    /// Randomize the background photo and persist the chosen image.
    func randomizePhoto() {
        if let randomName = photoNames.randomElement() {
            currentPhotoName = randomName
            storedPhotoName = randomName
            lastRandomizationTimestamp = Date().timeIntervalSince1970
        }
    }

    /// Change the photo based on the user's preference.
    func randomizePhotoIfNeeded() {
        if disableChangeEachLaunch {
            let lastDate = Date(timeIntervalSince1970: lastRandomizationTimestamp)
            if !Calendar.current.isDateInToday(lastDate) {
                randomizePhoto()
            } else {
                currentPhotoName = storedPhotoName
            }
        } else {
            randomizePhoto()
        }
    }
}

