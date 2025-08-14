import SwiftUI

struct MusicControlButton: View {
    var isPlaying: Bool
    var action: () -> Void

    struct HighlightStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding(16)
                .background(
                    Circle()
                        .fill(Color.white.opacity(configuration.isPressed ? 0.3 : 0))
                )
                .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(Color.white.opacity(0.9))
        }
        .buttonStyle(HighlightStyle())
    }
}
