import SwiftUI

struct NavigationCard: View {
    var title: String
    var background: Color = .mellowBlue
    var cornerRadius: CGFloat = 22
    var pillSize = CGSize(width: 38.431, height: 21.679)
    var isSelected: Bool = true

    // optional combo icons (use nil when not configured)
    var firstCombo: GestureType? = nil
    var secondCombo: GestureType? = nil
    var height: CGFloat = 100.72

    // optional tap action
    var action: (() -> Void)? = nil

    @ViewBuilder
    private var contentBody: some View {
        ZStack(alignment: .topTrailing) {
            // Card background - selected: filled, unselected: white with border
            if isSelected {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
            } else {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.whiteWhite)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(background, lineWidth: 1)
                    )
            }

            // Top-right pill with arrows (only if both icons provided)
            if let first = firstCombo, let second = secondCombo {
                if isSelected {
                    // Selected: white pill with blue icons
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
                    .padding(10) // outer padding around capsule
                } else {
                    // Unselected: blue pill with white icons
                    ComboPill(
                        firstGesture: first,
                        secondGesture: second,
                        foreground: .whiteWhite,
                        background: background,
                        size: pillSize,
                        paddingValue: 4.927,
                        iconSize: 11.825,
                        spacing: 4.927
                    )
                    .padding(10) // outer padding around capsule
                }
            }

            // Bottom-left title
            VStack {
                Spacer()
                HStack {
                    Text(title.uppercased())
                        .font(.system(size: 14, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(isSelected ? .whiteWhite : background)
                    Spacer()
                }
                .padding(12)
            }
        }
        .frame(height: height)
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
    NavigationCard(title: "Settings", background: .mellowBlue, cornerRadius: 28, firstCombo: .lookUp, secondCombo: .lookRight)
}
