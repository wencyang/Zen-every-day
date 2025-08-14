import SwiftUI

struct LegalView: View {
  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 16) {
        Text("Legal")
          .font(.title)
          .bold()
        Text(
          """
          By using this app, you agree to the following terms and conditions:

          This application is provided on an "as is" basis without any representations or warranties, express or implied. The developers, publishers, and distributors of this app shall not be liable for any damages arising from its use.

          All Bible text used in this application is sourced from the Authorized King James Version (KJV) which is in the public domain. No copyright infringement is intended.
          """
        )
        .font(.body)
      }
      .padding()
    }
    .navigationTitle("")
  }
}

struct LegalView_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      LegalView()
    }
  }
}
