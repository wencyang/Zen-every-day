import Photos
import SwiftUI
import UIKit

struct QuoteCardCreator: View {
  let quote: WisdomQuote
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject var backgroundManager: BackgroundImageManager
  @State private var showShareSheet = false
  @State private var generatedImage: UIImage?
  @State private var isGenerating = false
  @State private var showSuccessToast = false
  @State private var showPermissionAlert = false
  @State private var backgroundImage: UIImage?

  init(quote: WisdomQuote) {
    self.quote = quote
  }

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        ScrollView {
          VStack(spacing: 12) {
            if let bgImage = backgroundImage {
              QuoteCardPreview(quote: quote, backgroundImage: bgImage)
                .frame(height: 500)
                .padding()
            } else {
              ProgressView("Loading background...")
                .frame(height: 500)
                .padding()
            }

            Text("Your quote card will be created with today's background")
              .font(.caption)
              .foregroundColor(.secondary)
              .padding(.horizontal)

            Spacer(minLength: 20)
          }
        }

        VStack(spacing: 12) {
          Button(action: shareCard) {
            HStack {
              Image(systemName: "square.and.arrow.up")
                .font(.system(size: 20))
              Text("Share Quote Card")
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
      .navigationTitle("Create Quote Card")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") { dismiss() }
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
          QuoteShareSheet(items: [image, quote.text])
        }
      }
      .alert("Permission Denied", isPresented: $showPermissionAlert) {
        Button("Settings") {
          if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
          }
        }
        Button("Cancel", role: .cancel) {}
      }
      .toast(
        isShowing: $showSuccessToast,
        message: "Saved to Photos",
        icon: "checkmark.circle.fill",
        color: .green
      )
      .onAppear {
        if backgroundImage == nil {
          if let image = UIImage(named: backgroundManager.currentPhotoName) {
            backgroundImage = image
          } else if
            let dataAsset = NSDataAsset(name: backgroundManager.currentPhotoName),
            let image = UIImage(data: dataAsset.data)
          {
            backgroundImage = image
          }
        }
      }
    }
  }

  private func shareCard() {
    generateCard { image in
      generatedImage = image
      showShareSheet = true
    }
  }

  private func saveToPhotos() {
    generateCard { image in
      PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
        if status == .authorized || status == .limited {
          UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
          DispatchQueue.main.async {
            showSuccessToast = true
          }
        } else {
          DispatchQueue.main.async {
            showPermissionAlert = true
          }
        }
      }
    }
  }

  private func generateCard(completion: @escaping (UIImage) -> Void) {
    guard let bgImage = backgroundImage else { return }
    isGenerating = true
    DispatchQueue.global(qos: .userInitiated).async {
      let image = QuoteCardRenderer.render(quote: quote, background: bgImage)
      DispatchQueue.main.async {
        isGenerating = false
        completion(image)
      }
    }
  }
}

struct QuoteCardRenderer {
  static func render(quote: WisdomQuote, background: UIImage) -> UIImage {
    let size = CGSize(width: 1080, height: 1920)
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { ctx in
      let rect = CGRect(origin: .zero, size: size)
      background.draw(in: rect)
      UIColor.black.withAlphaComponent(0.4).setFill()
      ctx.fill(rect)

      let paragraph = NSMutableParagraphStyle()
      paragraph.alignment = .center

      let textAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont(name: "Georgia", size: 52)!,
        .foregroundColor: UIColor.white,
        .paragraphStyle: paragraph,
      ]
      let textRect = CGRect(x: 60, y: 300, width: size.width - 120, height: size.height - 600)
      (quote.text as NSString).draw(in: textRect, withAttributes: textAttributes)

      if let author = quote.author {
        let authorAttributes: [NSAttributedString.Key: Any] = [
          .font: UIFont(name: "Georgia", size: 32)!,
          .foregroundColor: UIColor.white.withAlphaComponent(0.9),
          .paragraphStyle: paragraph,
        ]
        let authorString = "- \(author)" as NSString
        let authorSize = authorString.size(withAttributes: authorAttributes)
        authorString.draw(at: CGPoint(x: (size.width - authorSize.width) / 2, y: textRect.maxY + 40), withAttributes: authorAttributes)
      }

      let brandingAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 22, weight: .regular),
        .foregroundColor: UIColor.white.withAlphaComponent(0.6),
      ]
      let branding = "Zen Every Day" as NSString
      let brandingSize = branding.size(withAttributes: brandingAttributes)
      branding.draw(
        at: CGPoint(
          x: (size.width - brandingSize.width) / 2,
          y: size.height - 120
        ),
        withAttributes: brandingAttributes
      )
    }
  }
}

struct QuoteCardPreview: View {
  let quote: WisdomQuote
  let backgroundImage: UIImage

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Image(uiImage: backgroundImage)
          .resizable()
          .scaledToFill()
          .frame(width: geometry.size.width, height: geometry.size.height)
          .clipped()
          .overlay(Color.black.opacity(0.4))

        VStack(spacing: 20) {
          Spacer()

          Text(quote.text)
            .font(
              .custom("Georgia", size: calculatePreviewFontSize(for: quote.text))
            )
            .fontWeight(.medium)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .lineSpacing(4)
            .padding(.horizontal, 20)
            .fixedSize(horizontal: false, vertical: true)

          if let author = quote.author {
            Text(author)
              .font(.custom("Georgia", size: 12))
              .foregroundColor(.white.opacity(0.9))
              .padding(.top, 8)
          }

          Spacer()

          HStack {
            Image(systemName: "quote.bubble.fill")
              .font(.system(size: 10))
              .foregroundColor(.white.opacity(0.7))
            Text("Zen Every Day")
              .font(.custom("Georgia", size: 10))
              .foregroundColor(.white.opacity(0.7))
          }
          .padding(.bottom, 20)
        }
      }
      .frame(width: geometry.size.width, height: geometry.size.height)
      .cornerRadius(20)
      .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
    }
  }

  private func calculatePreviewFontSize(for text: String) -> CGFloat {
    let length = text.count
    if length < 50 {
      return 20
    } else if length < 100 {
      return 18
    } else if length < 200 {
      return 16
    } else {
      return 14
    }
  }
}

struct QuoteShareSheet: UIViewControllerRepresentable {
  let items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
