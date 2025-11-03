import SwiftUI

struct NavigationCard: View {
    var title: String
    var background: Color = .customBlue
    var cornerRadius: CGFloat = 22
    var pillSize = CGSize(width: 45, height: 24.46)

    // optional combo icons (use nil when not configured)
    var firstCombo: String? = nil
    var secondCombo: String? = nil

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
                Capsule(style: .continuous)
                    .fill(.white)
                    .frame(width: pillSize.width, height: pillSize.height)
                    .overlay(
                        HStack(spacing: 4) {
                            Image(systemName: first)
                            Image(systemName: second)
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(background)
                        .padding(.horizontal, 6) // inner padding for icons
                    )
                    .padding(10) // outer padding around capsule
            }

            // Bottom-left title
            VStack {
                Spacer()
                HStack {
                    Text(title.uppercased())
                        .font(.system(size: 14, design: .rounded))
                        .tracking(3)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(12)
            }
        }
        .frame(width: 143.03, height: 100.72)
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

    NavigationCard(title: "Settings", background: .customBlue, cornerRadius: 28, firstCombo: "arrow.up",secondCombo: "arrow.right")
    
}
