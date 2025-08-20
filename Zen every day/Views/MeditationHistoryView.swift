import SwiftUI

struct MeditationHistoryView: View {
    @State private var sessions: [MeditationRecord] = []

    var body: some View {
        List {
            if sessions.isEmpty {
                Text("No meditation sessions yet.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(sessions, id: \.date) { session in
                    VStack(alignment: .leading) {
                        Text(session.date, style: .date)
                            .font(.headline)
                        Text(formatDuration(session.duration))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        if !session.ambientSound.isEmpty {
                            Text(session.ambientSound)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Meditation History")
        .onAppear(perform: loadHistory)
    }

    private func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: "meditationHistory"),
           let records = try? JSONDecoder().decode([MeditationRecord].self, from: data) {
            sessions = records.sorted { $0.date > $1.date }
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

struct MeditationHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            MeditationHistoryView()
        }
    }
}

