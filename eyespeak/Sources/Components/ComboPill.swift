import SwiftUI

struct ComboPill: View {
    let firstGesture: GestureType
    let secondGesture: GestureType

    var foreground: Color = .mellowBlue
    var background: Color = .whiteWhite
    var size: CGSize = CGSize(width: 38.431, height: 21.679)
    var paddingValue: CGFloat = 4.927
    var iconSize: CGFloat = 11.825
    var spacing: CGFloat = 4.927
    var cornerRadius: CGFloat = 64.0517
    var isEnabled: Bool = true
    var isHighlighted: Bool = false
    var ensureMinimumHitArea: Bool = false
    var accessibilityLabel: String?

    private var resolvedForeground: Color {
        foreground.opacity(isEnabled ? 1 : 0.4)
    }

    private var resolvedAccessibilityLabel: String {
        if let accessibilityLabel {
            return accessibilityLabel
        }
        let first = description(for: firstGesture)
        let second = description(for: secondGesture)
        return "Combo \(first) then \(second)"
    }

    var body: some View {
        let pill = HStack(alignment: .top, spacing: spacing) {
            icon(for: firstGesture)
            icon(for: secondGesture)
        }
        .foregroundStyle(resolvedForeground)
        .padding(paddingValue)
        .frame(width: size.width, height: size.height, alignment: .top)
        .background(background)
        .cornerRadius(cornerRadius, antialiased: true)
        .shadow(color: .black.opacity(isHighlighted ? 0.12 : 0), radius: isHighlighted ? 4 : 0, x: 0, y: isHighlighted ? 2 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(resolvedAccessibilityLabel)

        if ensureMinimumHitArea {
            pill
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        } else {
            pill
        }
    }

    @ViewBuilder
    private func icon(for gesture: GestureType) -> some View {
        if let assetName = gesture.legendAssetName {
            Image(assetName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize, alignment: .top)
        } else {
            Image(systemName: gesture.iconName)
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize, alignment: .top)
        }
    }

    private func description(for gesture: GestureType) -> String {
        gesture.displayName
    }
}

#Preview {
    VStack(spacing: 16) {
        ComboPill(firstGesture: .lookUp, secondGesture: .lookRight)
        ComboPill(firstGesture: .lookLeft, secondGesture: .lookDown, isHighlighted: true)
        ComboPill(firstGesture: .lookLeft, secondGesture: .lookRight, isEnabled: false, ensureMinimumHitArea: true)
    }
    .padding()
    .background(Color.boneWhite)
}
