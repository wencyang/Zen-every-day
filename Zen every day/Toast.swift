import Combine
import SwiftUI

// MARK: - Toast Notification System

// Toast notification view
struct ToastView: View {
  let message: String
  let icon: String
  let color: Color
  @Binding var isShowing: Bool

  var body: some View {
    HStack(spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 16, weight: .medium))
        .foregroundColor(color)

      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.primary)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 10)
    .background(
      Capsule()
        .fill(.ultraThinMaterial)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    )
    .scaleEffect(isShowing ? 1.0 : 0.8)
    .opacity(isShowing ? 1.0 : 0.0)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isShowing)
  }
}

// Toast notification modifier
struct ToastModifier: ViewModifier {
  @Binding var isShowing: Bool
  let message: String
  let icon: String
  let color: Color
  let duration: Double

  func body(content: Content) -> some View {
    ZStack {
      content

      if isShowing {
        VStack {
          Spacer()

          ToastView(
            message: message,
            icon: icon,
            color: color,
            isShowing: $isShowing
          )
          .padding(.bottom, 100)  // Account for tab bar

          Spacer()
        }
        .allowsHitTesting(false)
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
    .onChange(of: isShowing) { oldValue, newValue in
      if newValue {
        // Auto-dismiss after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
          withAnimation(.easeOut(duration: 0.3)) {
            isShowing = false
          }
        }
      }
    }
  }
}

// Convenient extension for easy use
extension View {
  func toast(
    isShowing: Binding<Bool>,
    message: String,
    icon: String = "checkmark.circle.fill",
    color: Color = .green,
    duration: Double = 1.5
  ) -> some View {
    self.modifier(
      ToastModifier(
        isShowing: isShowing,
        message: message,
        icon: icon,
        color: color,
        duration: duration
      )
    )
  }
}

