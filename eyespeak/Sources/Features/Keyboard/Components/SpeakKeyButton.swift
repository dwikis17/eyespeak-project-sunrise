import SwiftUI

/// A function key that speaks the current typed text.
struct SpeakKeyButton: View {
    @ObservedObject var model: KeyboardSpeechServiceModel
    /// Supplies the latest text to speak.
    var textProvider: () -> String
    /// Optional combo to show on the key.
    var assignedCombo: ActionCombo?
    /// Optional handler to assign a combo to this key.
    var onAssignCombo: (() -> Void)?
    /// Highlighted state for scanning feedback.
    var isHighlighted: Bool = false

    var body: some View {
        Button(action: { model.speak(textProvider()) }) {
            ZStack(alignment: .top) {
                HStack(spacing: 6) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(minWidth: 82, minHeight: 60)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.mellowBlue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                        )
                )

                if let combo = assignedCombo {
                    ComboBadgeView(combo: combo)
                        .padding(6)
                }
            }
        }
        .accessibilityLabel("Speak")
        .contextMenu {
            Button("Assign combo") { onAssignCombo?() }
        }
    }
}