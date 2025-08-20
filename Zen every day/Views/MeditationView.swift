import SwiftUI

struct MeditationView: View {
    var body: some View {
        MeditationTimerView()
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
