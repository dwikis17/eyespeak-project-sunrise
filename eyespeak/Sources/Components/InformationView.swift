import SwiftUI

// Reusable Card wrapper
struct Card<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack {
            content
        }
        .padding() // internal padding for content
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
        .fixedSize(horizontal: false, vertical: true) // important: allow card to fit its content height
    }
}

struct InformationView: View {
    @EnvironmentObject private var viewModel: AACViewModel

    var body: some View {
        VStack(spacing: 16) {
            currentInputSection
            if viewModel.isGestureMode {
                AACFaceTrackingPanel()
            } else {
                gestureModePlaceholder
            }
        }
    }

    private var currentInputSection: some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                Text("CURRENT INPUT")
                    .font(.headline)
                    .foregroundColor(.primary)

                Divider()

                // Inner gradient card with live last-input icons
                ZStack(alignment: .center) {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(LinearGradient.redOrange)
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)

                    // Show up to last two gestures as large, white icons
                    HStack(spacing: 28) {
                        ForEach(Array(viewModel.gestureInputManager.gestureSequence.enumerated()), id: \.offset) { _, gesture in
                            Image(systemName: gesture.iconName)
                                .font(.system(size: 44, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: .black.opacity(0.12), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .frame(height: 107)

                // Live countdown bar linked to gesture timing window
                GeometryReader { geo in
                    TimelineView(.periodic(from: .now, by: 0.05)) { context in
                        let fraction = viewModel.gestureInputManager.remainingTimeFraction(referenceDate: context.date)
                        ZStack(alignment: .leading) {
                            Capsule()
                                .frame(height: 6)
                                .foregroundColor(Color(.systemGray5))
                            Capsule()
                                .frame(width: geo.size.width * fraction, height: 6)
                                .foregroundColor(Color(red: 246/255, green: 146/255, blue: 79/255))
                        }
                        .animation(.easeOut(duration: 0.1), value: fraction)
                    }
                }
                .frame(height: 20)
            }
        }
    }

    private var gestureModePlaceholder: some View {
        Card {
            VStack(spacing: 16) {
                Text("Gesture Mode")
                    .font(.headline)
                    .foregroundColor(.primary)

                VStack(spacing: 8) {
                    Text("Turn on gesture mode to control the grid with your eyes.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 40) {
                        Image(systemName: "arrow.left")
                        Image(systemName: "eye")
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(.blue.opacity(0.3))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity) // placeholder card stretches horizontally but still fits content height
    }
}

#Preview {
    InformationView()
        .environmentObject(AACDIContainer.shared.makeAACViewModel())
        .frame(width: 360)
}
