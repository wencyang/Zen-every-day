import SwiftUI

struct MeditationView: View {
    var body: some View {
        MeditationTimerView()
            .navigationTitle("")
    }
}

struct MeditationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MeditationView()
        }
    }
}
