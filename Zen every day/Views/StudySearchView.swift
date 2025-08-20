import SwiftUI

struct StudySearchView: View {
    @State private var selection = 0

    var body: some View {
        VStack {
            Picker("Mode", selection: $selection) {
                Text("Study").tag(0)
                Text("Search").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selection == 0 {
                StudyView()
            } else {
                SearchView()
            }
        }
        .navigationTitle(selection == 0 ? "Study" : "Search")
    }
}

struct StudySearchView_Previews: PreviewProvider {
    static var previews: some View {
        StudySearchView()
            .environmentObject(UserSettings())
            .environmentObject(SavedQuotesManager())
    }
}
