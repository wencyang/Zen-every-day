import SwiftUI

struct AppLoadingView: View {
  var body: some View {
    VStack(spacing: 12) {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
        .scaleEffect(1.5)

      Text("Loading")
        .font(.headline)
        .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
  }
}

struct AppLoadingView_Previews: PreviewProvider {
  static var previews: some View {
    AppLoadingView()
  }
}
