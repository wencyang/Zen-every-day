import StoreKit
import SwiftUI

class DonationManager: NSObject, ObservableObject, SKProductsRequestDelegate,
  SKPaymentTransactionObserver
{
  @Published var products: [SKProduct] = []
  @Published var isLoading = false
  @Published var purchaseError: String?
  @Published var showThankYou = false

  // Your In-App Purchase product IDs - you need to create these in App Store Connect
  private let productIDs = Set([
    "com.dailybible.donation.coffee",  // $0.99
    "com.dailybible.donation.lunch",  // $1.99
    "com.dailybible.donation.dinner",  // $2.99
  ])

  override init() {
    super.init()
    SKPaymentQueue.default().add(self)
    fetchProducts()
  }

  deinit {
    SKPaymentQueue.default().remove(self)
  }

  func fetchProducts() {
    isLoading = true
    let request = SKProductsRequest(productIdentifiers: productIDs)
    request.delegate = self
    request.start()
  }

  func purchase(product: SKProduct) {
    guard SKPaymentQueue.canMakePayments() else {
      purchaseError = "Purchases are disabled on this device"
      return
    }

    let payment = SKPayment(product: product)
    SKPaymentQueue.default().add(payment)
  }

  // MARK: - SKProductsRequestDelegate
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    DispatchQueue.main.async {
      self.products = response.products.sorted { $0.price.doubleValue < $1.price.doubleValue }
      self.isLoading = false
    }
  }

  func request(_ request: SKRequest, didFailWithError error: Error) {
    DispatchQueue.main.async {
      self.purchaseError = error.localizedDescription
      self.isLoading = false
    }
  }

  // MARK: - SKPaymentTransactionObserver
  func paymentQueue(
    _ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]
  ) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        completeTransaction(transaction)
      case .failed:
        failedTransaction(transaction)
      case .restored:
        restoreTransaction(transaction)
      case .deferred, .purchasing:
        break
      @unknown default:
        break
      }
    }
  }

  private func completeTransaction(_ transaction: SKPaymentTransaction) {
    SKPaymentQueue.default().finishTransaction(transaction)
    DispatchQueue.main.async {
      self.showThankYou = true
    }
  }

  private func failedTransaction(_ transaction: SKPaymentTransaction) {
    if let error = transaction.error as? SKError {
      if error.code != .paymentCancelled {
        DispatchQueue.main.async {
          self.purchaseError = error.localizedDescription
        }
      }
    }
    SKPaymentQueue.default().finishTransaction(transaction)
  }

  private func restoreTransaction(_ transaction: SKPaymentTransaction) {
    SKPaymentQueue.default().finishTransaction(transaction)
  }
}
