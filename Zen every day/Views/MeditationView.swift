import SwiftUI

struct MeditationView: View {
    var body: some View {
        VStack {
            Text("Meditation content coming soon")
                .font(.title2)
                .padding()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Meditation")
    }
}

struct MeditationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MeditationView()
        }
    }
}
