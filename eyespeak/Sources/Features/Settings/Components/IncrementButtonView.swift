import SwiftUI

struct IncrementButtonView: View {
    var title: String
    var background: Color = .mellowBlue
    var cornerRadius: CGFloat = 14
    var pillSize = CGSize(width: 38.32, height: 21.41)

    // optional combo icons (use nil when not configured)
    var firstCombo: GestureType? = nil
    var secondCombo: GestureType? = nil
    var height: CGFloat = 115.92

    // optional tap action
    var action: (() -> Void)? = nil

    @ViewBuilder
    private var contentBody: some View {
        ZStack(alignment: .topTrailing) {
            // Card background
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(background)

            // Top-right white pill with arrows (only if both icons provided)
            if let first = firstCombo, let second = secondCombo {
                ComboPill(
                    firstGesture: first,
                    secondGesture: second,
                    foreground: background,
                    background: .whiteWhite,
                    size: pillSize,
                    paddingValue: 4.927,
                    iconSize: 11.825,
                    spacing: 4.927
                )
                .padding(10)  // outer padding around capsule
            }

            // Bottom-left title
            Text(title.uppercased())
                .font(.system(size: 30, design: .rounded))
                .tracking(3)
                .foregroundStyle(.white)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: .center
                )
        }
        .frame(width: 68.75, height: height)
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
    }

    var body: some View {
        // If an action is provided, make the entire card tappable via Button
        if let action = action {
            Button(action: action) {
                contentBody
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            contentBody
        }
    }
}

#Preview {
    IncrementButtonView(
        title: "+",
        firstCombo: .lookUp,
        secondCombo: .lookRight
    )
}
