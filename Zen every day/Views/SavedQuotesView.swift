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

              HStack(spacing: 8) {
                Spacer()
                Button(action: {
                  savedQuotesManager.removeSavedQuote(saved)
                }) {
                  Image(systemName: "bookmark.slash")
                    .font(.system(size: 16))
                    .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())

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
            .padding()
            .listRowBackground(
              DebugBackgroundImageView(
                photoName: saved.backgroundPhotoName,
                quoteText: String(saved.text.prefix(30))
              )
              .clipShape(RoundedRectangle(cornerRadius: 12))
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
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
    .onAppear {
      // Update existing saved quotes that might not have backgrounds
      savedQuotesManager.updateExistingSavedQuotesWithBackgrounds()
    }
  }
}

// Debug version with extensive logging (fixed - no print in view builder)
struct DebugBackgroundImageView: View {
  let photoName: String?
  let quoteText: String
  
  var body: some View {
    Group {
      if let photoName = photoName, !photoName.isEmpty {
        // Method 1: Try UIImage(named:) - for images in main bundle
        if let image = UIImage(named: photoName) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .overlay(Color.black.opacity(0.2))
            .onAppear {
              print("✅ [\(quoteText)] SUCCESS with UIImage(named:) for \(photoName)")
            }
        }
        // Method 2: Try NSDataAsset - for images in asset catalog
        else if let dataAsset = NSDataAsset(name: photoName),
                let image = UIImage(data: dataAsset.data) {
          Image(uiImage: image)
            .resizable()
            .scaledToFill()
            .overlay(Color.black.opacity(0.2))
            .onAppear {
              print("✅ [\(quoteText)] SUCCESS with NSDataAsset for \(photoName)")
            }
        }
        // Method 3: Try with different photo names as fallback
        else if let fallbackImage = tryFallbackPhotos() {
          Image(uiImage: fallbackImage)
            .resizable()
            .scaledToFill()
            .overlay(Color.black.opacity(0.2))
            .onAppear {
              print("✅ [\(quoteText)] SUCCESS with fallback image")
            }
        }
        // Method 4: Create a test gradient to confirm the view is working
        else {
          LinearGradient(
            gradient: Gradient(colors: [
              Color.blue.opacity(0.6),
              Color.purple.opacity(0.6),
              Color.pink.opacity(0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .overlay(
            VStack {
              Text("DEBUG")
                .font(.caption)
                .foregroundColor(.white)
              Text(photoName)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.8))
            }
          )
          .onAppear {
            print("❌ [\(quoteText)] ALL METHODS FAILED for \(photoName) - using gradient")
          }
        }
      } else {
        // No photo name - try default or show debug info
        if let defaultImage = UIImage(named: "photo1") {
          Image(uiImage: defaultImage)
            .resizable()
            .scaledToFill()
            .overlay(Color.black.opacity(0.2))
            .onAppear {
              print("✅ [\(quoteText)] Using default photo1")
            }
        } else {
          LinearGradient(
            gradient: Gradient(colors: [
              Color.orange.opacity(0.6),
              Color.red.opacity(0.6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
          .overlay(
            Text("NO PHOTO")
              .font(.caption)
              .foregroundColor(.white)
          )
          .onAppear {
            print("❌ [\(quoteText)] No photoName provided and no default photo1 found")
          }
        }
      }
    }
  }
  
  private func tryFallbackPhotos() -> UIImage? {
    // Try common photo names
    let fallbackNames = ["photo1", "photo2", "photo3", "photo4", "photo5"]
    
    for name in fallbackNames {
      if let image = UIImage(named: name) {
        print("📸 Found fallback image: \(name)")
        return image
      }
      if let dataAsset = NSDataAsset(name: name),
         let image = UIImage(data: dataAsset.data) {
        print("📸 Found fallback NSDataAsset: \(name)")
        return image
      }
    }
    
    print("📸 No fallback images found")
    return nil
  }
}

// Extension for SavedQuotesManager to update existing quotes
extension SavedQuotesManager {
    func updateExistingSavedQuotesWithBackgrounds() {
        print("🔄 Updating existing saved quotes with backgrounds...")
        var updated = false
        
        for i in 0..<savedQuotes.count {
            if savedQuotes[i].backgroundPhotoName == nil || savedQuotes[i].backgroundPhotoName?.isEmpty == true {
                // Generate a random background for quotes that don't have one
                let newBackground = generateRandomPhotoName()
                print("🔄 Updating quote \(i) with background: \(newBackground)")
                
                savedQuotes[i] = SavedQuote(
                    id: savedQuotes[i].id,
                    author: savedQuotes[i].author,
                    text: savedQuotes[i].text,
                    work: savedQuotes[i].work,
                    dateSaved: savedQuotes[i].dateSaved,
                    backgroundPhotoName: newBackground
                )
                updated = true
            }
        }
        
        if updated {
            persistSavedQuotes()
            objectWillChange.send()
        }
    }
    
    private func generateRandomPhotoName() -> String {
        var names: [String] = []
        var index = 1
        while index <= 1000 {
            let name = "photo\(index)"
            if UIImage(named: name) != nil || NSDataAsset(name: name) != nil {
                names.append(name)
                index += 1
            } else {
                break
            }
        }
        let photoNames = names.isEmpty ? ["photo1"] : names
        return photoNames.randomElement() ?? "photo1"
    }
    
    private func persistSavedQuotes() {
        if let encoded = try? JSONEncoder().encode(savedQuotes) {
            UserDefaults.standard.set(encoded, forKey: "savedQuotes")
        }
    }
}
