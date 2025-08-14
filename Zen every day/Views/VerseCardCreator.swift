import Photos
import SwiftUI
import UIKit

// MARK: - Verse Card Creator View
struct VerseCardCreator: View {
  let verse: Verse
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var backgroundManager: BackgroundImageManager
  @State private var showShareSheet = false
  @State private var generatedImage: UIImage?
  @State private var isGenerating = false
  @State private var showSuccessToast = false
  @State private var showPermissionAlert = false
  @State private var backgroundImage: UIImage?

  init(verse: Verse) {
    self.verse = verse
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Preview Section
        ScrollView {
          VStack(spacing: 12) {  // Scaled down spacing
            // Card Preview
            if let bgImage = backgroundImage {
              VerseCardPreview(verse: verse, backgroundImage: bgImage)
                .frame(height: 500)
                .padding()
            } else {
              // Loading state
              ProgressView("Loading background...")
                .frame(height: 500)
                .padding()
            }

            // Info text
            Text("Your verse card will be created with today's background")
              .font(.caption)
              .foregroundColor(.secondary)
              .padding(.horizontal)

            Spacer(minLength: 20)
          }
        }

        // Action Buttons
        VStack(spacing: 12) {
          // Share Button
          Button(action: shareCard) {
            HStack {
              Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20))
              Text("Share Verse Card")
                .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue)
            )
          }
          .disabled(isGenerating || backgroundImage == nil)

          // Save to Photos Button
          Button(action: saveToPhotos) {
            HStack {
              Image(systemName: "square.and.arrow.down")
                .font(.system(size: 20))
              Text("Save to Photos")
                .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
              RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue, lineWidth: 2)
            )
          }
          .disabled(isGenerating || backgroundImage == nil)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
      }
      .navigationTitle("Create Verse Card")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .overlay(
        Group {
          if isGenerating {
            Color.black.opacity(0.3)
              .ignoresSafeArea()
              .overlay(
                ProgressView()
                  .scaleEffect(1.5)
                  .tint(.white)
              )
          }
        }
      )
      .sheet(isPresented: $showShareSheet) {
        if let image = generatedImage {
          VerseShareSheet(items: [image, "\(verse.book_name) \(verse.chapter):\(verse.verse)"])
        }
      }
      .alert("Permission Denied", isPresented: $showPermissionAlert) {
        Button("Settings") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
        }
        Button("Cancel", role: .cancel) {}
      } message: {
        Text(
          "Please allow Daily Bible to access your photo library in Settings to save verse cards.")
      }
      .overlay(
        Group {
          if showSuccessToast {
            VStack {
              Spacer()
              HStack {
                Image(systemName: "checkmark.circle.fill")
                  .foregroundColor(.white)
                Text("Saved to Photos")
                  .foregroundColor(.white)
                  .font(.system(size: 16, weight: .medium))
              }
              .padding()
              .background(
                Capsule()
                  .fill(Color.green)
              )
              .padding(.bottom, 100)
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
          }
        }
      )
    }
    .onAppear {
      loadCurrentBackgroundImage()
    }
  }

  private func loadCurrentBackgroundImage() {
    let photoName = backgroundManager.currentPhotoName

    // Try multiple ways to load the image
    if let image = UIImage(named: photoName) {
      self.backgroundImage = image
    } else if let asset = NSDataAsset(name: photoName),
      let image = UIImage(data: asset.data)
    {
      self.backgroundImage = image
    } else {
      // Create a fallback gradient image
      self.backgroundImage = createGradientImage(size: CGSize(width: 1080, height: 1920))
    }
  }

  private func createGradientImage(size: CGSize) -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
      let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: [0.0, 1.0]
      )!

      context.cgContext.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: size.width, y: size.height),
        options: []
      )
    }
  }

  /// Draws an image into the given rect using aspect fill to preserve
  /// the photo's aspect ratio. This prevents distortion when the source
  /// image has a different ratio than the verse card canvas.
  private func drawImage(_ image: UIImage, in rect: CGRect) {
    let imageSize = image.size
    let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
    let drawWidth = imageSize.width * scale
    let drawHeight = imageSize.height * scale
    let drawRect = CGRect(
      x: rect.midX - drawWidth / 2,
      y: rect.midY - drawHeight / 2,
      width: drawWidth,
      height: drawHeight
    )
    image.draw(in: drawRect)
  }

  private func shareCard() {
    guard let bgImage = backgroundImage else { return }

    isGenerating = true

    DispatchQueue.main.async {
      self.generatedImage = self.createVerseCard(backgroundImage: bgImage)
      self.showShareSheet = true
      self.isGenerating = false
    }
  }

  private func saveToPhotos() {
    // Check photo library permission first
    let status = PHPhotoLibrary.authorizationStatus()

    switch status {
    case .authorized, .limited:
      // Permission already granted, save the image
      performSave()

    case .notDetermined:
      // Request permission
      PHPhotoLibrary.requestAuthorization { newStatus in
        DispatchQueue.main.async {
          if newStatus == .authorized || newStatus == .limited {
            self.performSave()
          } else {
            self.showPermissionAlert = true
          }
        }
      }

    case .denied, .restricted:
      showPermissionAlert = true

    @unknown default:
      break
    }
  }

  private func performSave() {
    guard let bgImage = backgroundImage else { return }

    isGenerating = true

    DispatchQueue.main.async {
      if let cardImage = self.createVerseCard(backgroundImage: bgImage) {
        UIImageWriteToSavedPhotosAlbum(cardImage, nil, nil, nil)

        // Show success toast
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
          self.showSuccessToast = true
        }

        // Dismiss the view after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
          self.dismiss()
        }
      }

      self.isGenerating = false
    }
  }

  private func createVerseCard(backgroundImage: UIImage) -> UIImage? {
    let size = CGSize(width: 1080, height: 1920)
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.image { context in
      let rect = CGRect(origin: .zero, size: size)

      // Draw background image using aspect fill to avoid distortion
      drawImage(backgroundImage, in: rect)

      // Draw dark overlay
      context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
      context.cgContext.fill(rect)

      // Set up text attributes
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .center
      paragraphStyle.lineSpacing = 16  // Increased line spacing

      // Calculate font size based on text length - INCREASED SIZES
      let fontSize = calculateFontSize(for: verse.text.cleanVerse)

      // Quote marks removed - cleaner design

      // Draw verse text - LARGER FONT
      let verseAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "Georgia", size: fontSize)
          ?? UIFont.systemFont(ofSize: fontSize, weight: .medium),
        .foregroundColor: UIColor.white,
        .paragraphStyle: paragraphStyle,
      ]

      let verseText = verse.text.cleanVerse as NSString
      let textHeight = verseText.boundingRect(
        with: CGSize(width: size.width - 120, height: .greatestFiniteMagnitude),
        options: [.usesLineFragmentOrigin, .usesFontLeading],
        attributes: verseAttributes,
        context: nil
      ).height

      let verseRect = CGRect(
        x: 60,
        y: (size.height - textHeight) / 2,
        width: size.width - 120,
        height: textHeight
      )

      verseText.draw(in: verseRect, withAttributes: verseAttributes)

      // Quote marks removed for cleaner design

      // Draw reference - LARGER
      let referenceAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "Georgia-Bold", size: 32)  // Increased from 26
          ?? UIFont.systemFont(ofSize: 32, weight: .semibold),
        .foregroundColor: UIColor.white.withAlphaComponent(0.9),
      ]

      let reference = "\(verse.book_name) \(verse.chapter):\(verse.verse)" as NSString
      let referenceSize = reference.size(withAttributes: referenceAttributes)
      reference.draw(
        at: CGPoint(
          x: (size.width - referenceSize.width) / 2,
          y: (size.height + textHeight) / 2 + 100  // Increased spacing
        ),
        withAttributes: referenceAttributes
      )

      // Draw app branding - LARGER
      let brandingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 22, weight: .regular),  // Increased from 18
        .foregroundColor: UIColor.white.withAlphaComponent(0.6),
      ]

      let branding = "Daily Bible" as NSString
      let brandingSize = branding.size(withAttributes: brandingAttributes)
      branding.draw(
        at: CGPoint(
          x: (size.width - brandingSize.width) / 2,
          y: size.height - 120  // Increased spacing
        ),
        withAttributes: brandingAttributes
      )
    }
  }

  private func calculateFontSize(for text: String) -> CGFloat {
    let length = text.count
    if length < 50 {
      return 52  // Significantly increased from 32
    } else if length < 100 {
      return 46  // Significantly increased from 28
    } else if length < 200 {
      return 40  // Significantly increased from 24
    } else {
      return 34  // Significantly increased from 20
    }
  }
}

// MARK: - Verse Card Preview
struct VerseCardPreview: View {
  let verse: Verse
  let backgroundImage: UIImage

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Background
        Image(uiImage: backgroundImage)
          .resizable()
          .scaledToFill()
          .frame(width: geometry.size.width, height: geometry.size.height)
          .clipped()
          .overlay(
            Color.black.opacity(0.4)
          )

        // Content
        VStack(spacing: 0) {
          Spacer()

          // Verse Text
          VStack(spacing: 20) {
            // Verse text - SCALED DOWN FOR PREVIEW
            Text(verse.text.cleanVerse)
              .font(
                .custom("Georgia", size: calculatePreviewFontSize(for: verse.text.cleanVerse))
              )
              .fontWeight(.medium)
              .foregroundColor(.white)
              .multilineTextAlignment(.center)
              .lineSpacing(4)  // Scaled down line spacing
              .padding(.horizontal, 20)  // Scaled down padding
              .fixedSize(horizontal: false, vertical: true)  // Show complete text

            // Reference - SCALED DOWN FOR PREVIEW
            Text("\(verse.book_name) \(verse.chapter):\(verse.verse)")
              .font(.custom("Georgia", size: 12))  // Scaled down from 32
              .fontWeight(.semibold)
              .foregroundColor(.white.opacity(0.9))
              .padding(.top, 8)  // Scaled down spacing
          }
          .padding(.vertical, 30)  // Scaled down padding

          Spacer()

          // App branding - SCALED DOWN FOR PREVIEW
          HStack {
            Image(systemName: "book.closed.fill")
              .font(.system(size: 10))  // Scaled down
              .foregroundColor(.white.opacity(0.7))
            Text("Daily Bible")
              .font(.custom("Georgia", size: 10))  // Scaled down from 22
              .foregroundColor(.white.opacity(0.7))
          }
          .padding(.bottom, 20)  // Scaled down padding
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .cornerRadius(20)
      .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
  }

  private func calculatePreviewFontSize(for text: String) -> CGFloat {
    // Scale down fonts for preview (about 40% of generated card size)
    let length = text.count
    if length < 50 {
      return 20  // Scaled down from 52
    } else if length < 100 {
      return 18  // Scaled down from 46
    } else if length < 200 {
      return 16  // Scaled down from 40
    } else {
      return 14  // Scaled down from 34
    }
  }
}

// Share Sheet for iOS - Renamed to avoid conflict
struct VerseShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
