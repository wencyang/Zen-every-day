import StoreKit
import SwiftUI

struct DonationView: View {
  @StateObject private var donationManager = DonationManager()
  @EnvironmentObject var settings: UserSettings
  @State private var showingThankYouAlert = false

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Header
        VStack(spacing: 16) {
          Image(systemName: "cup.and.saucer.fill")
            .font(.system(size: 60))
            .foregroundColor(.brown)
            .padding()
            .background(
              Circle()
                .fill(Color.brown.opacity(0.1))
            )

          Text("Support Daily Bible")
            .font(.title)
            .fontWeight(.bold)

          Text("Buy me a coffee ☕")
            .font(.title2)
            .foregroundColor(.secondary)
        }
        .padding(.top, 20)

        // Message
        VStack(spacing: 16) {
          Text("Daily Bible is completely free and ad-free, and it always will be.")
            .font(.system(size: settings.fontSize))
            .multilineTextAlignment(.center)
            .padding(.horizontal)

          Text(
            "If you enjoy using this app and would like to support its development, you can buy me a coffee. Your support helps keep the app updated and motivates me to add new features!"
          )
          .font(.system(size: settings.fontSize * 0.9))
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal)
        }

        // Donation Options
        if donationManager.isLoading {
          ProgressView()
            .padding()
        } else if donationManager.products.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle")
              .font(.system(size: 40))
              .foregroundColor(.secondary)
            Text("Unable to load donation options")
              .foregroundColor(.secondary)
            Button("Try Again") {
              donationManager.fetchProducts()
            }
            .foregroundColor(.blue)
          }
          .padding()
        } else {
          VStack(spacing: 16) {
            ForEach(donationManager.products, id: \.productIdentifier) { product in
              DonationOptionButton(
                product: product,
                action: {
                  donationManager.purchase(product: product)
                }
              )
            }
          }
          .padding(.horizontal)
        }

        // Footer
        VStack(spacing: 12) {
          Image(systemName: "heart.fill")
            .font(.system(size: 24))
            .foregroundColor(.pink)

          Text("Thank you for your support!")
            .font(.system(size: settings.fontSize * 0.9))
            .foregroundColor(.secondary)
        }
        .padding(.top, 20)
        .padding(.bottom, 40)
      }
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle("Support")
    .navigationBarTitleDisplayMode(.inline)
    .alert("Thank You! ❤️", isPresented: $donationManager.showThankYou) {
      Button("OK") {}
    } message: {
      Text(
        "Your support means a lot! Thank you for helping keep Daily Bible free and ad-free for everyone."
      )
    }
    .alert("Error", isPresented: .constant(donationManager.purchaseError != nil)) {
      Button("OK") {
        donationManager.purchaseError = nil
      }
    } message: {
      Text(donationManager.purchaseError ?? "An error occurred")
    }
  }
}

struct DonationOptionButton: View {
  let product: SKProduct
  let action: () -> Void

  var icon: String {
    switch product.price.doubleValue {
    case 0..<1.50:
      return "cup.and.saucer.fill"
    case 1.50..<2.50:
      return "takeoutbag.and.cup.and.straw.fill"
    default:
      return "fork.knife"
    }
  }

  var title: String {
    switch product.price.doubleValue {
    case 0..<1.50:
      return "Buy me a coffee"
    case 1.50..<2.50:
      return "Buy me lunch"
    default:
      return "Buy me dinner"
    }
  }

  var subtitle: String {
    switch product.price.doubleValue {
    case 0..<1.50:
      return "A small token of appreciation"
    case 1.50..<2.50:
      return "Fuel for more features"
    default:
      return "Generous support for development"
    }
  }

  var body: some View {
    Button(action: action) {
      HStack {
        Image(systemName: icon)
          .font(.system(size: 30))
          .foregroundColor(.white)
          .frame(width: 50, height: 50)
          .background(
            RoundedRectangle(cornerRadius: 12)
              .fill(Color.brown)
          )

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.headline)
            .foregroundColor(.primary)
          Text(subtitle)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Spacer()

        Text(priceString(for: product))
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(.blue)
      }
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.secondarySystemGroupedBackground))
          .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }

  func priceString(for product: SKProduct) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = product.priceLocale
    return formatter.string(from: product.price) ?? "$\(product.price)"
  }
}

struct DonationView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      DonationView()
        .environmentObject(UserSettings())
    }
  }
}
