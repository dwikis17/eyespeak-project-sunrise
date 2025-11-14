import SwiftUI

@ViewBuilder
private func comboIcon(for gesture: GestureType, iconSize: CGFloat, alignment: Alignment = .center) -> some View {
    if let assetName = gesture.legendAssetName {
        Image(assetName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize, alignment: alignment)
    } else {
        Image(systemName: gesture.iconName)
            .resizable()
            .scaledToFit()
            .frame(width: iconSize, height: iconSize, alignment: alignment)
    }
}

private func description(for gesture: GestureType) -> String {
    gesture.displayName
}

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
    var ensureMinimumHitArea: Bool = false
    var accessibilityLabel: String?
    @AppStorage("fontScale") private var fontScaleRaw: String = "medium"

    private var scaleMultiplier: CGFloat {
        FontScale(rawValue: fontScaleRaw)?.multiplier ?? FontScale.medium.multiplier
    }

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
        let scaledSpacing = spacing * scaleMultiplier
        let scaledPadding = paddingValue * scaleMultiplier
        let scaledIconSize = iconSize * scaleMultiplier
        let scaledSize = CGSize(
            width: size.width * scaleMultiplier,
            height: size.height * scaleMultiplier
        )
        let scaledCornerRadius = cornerRadius * scaleMultiplier

        let pill = HStack(alignment: .top, spacing: scaledSpacing) {
            comboIcon(for: firstGesture, iconSize: scaledIconSize)
            comboIcon(for: secondGesture, iconSize: scaledIconSize)
        }
        .foregroundStyle(resolvedForeground)
        .padding(scaledPadding)
        .frame(width: scaledSize.width, height: scaledSize.height, alignment: .top)
        .background(background)
        .cornerRadius(scaledCornerRadius, antialiased: true)
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
}

struct OutlineComboPill: View {
    let firstGesture: GestureType
    let secondGesture: GestureType

    var strokeColor: Color = .mellowBlue
    var background: Color = .whiteWhite
    var iconColor: Color?
    var spacing: CGFloat = 3.83262
    var paddingValue: CGFloat = 3.83262
    var iconSize: CGFloat = 11.825
    var size: CGSize = CGSize(width: 38.431, height: 21.679)
    var cornerRadius: CGFloat = 49.82401
    var insetAmount: CGFloat = 0.38
    var strokeWidth: CGFloat = 0.76652
    var isEnabled: Bool = true
    var accessibilityLabel: String?
    @AppStorage("fontScale") private var fontScaleRaw: String = "medium"

    private var scaleMultiplier: CGFloat {
        FontScale(rawValue: fontScaleRaw)?.multiplier ?? FontScale.medium.multiplier
    }

    private var resolvedColor: Color {
        let base = iconColor ?? strokeColor
        return base.opacity(isEnabled ? 1 : 0.4)
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
        let scaledSpacing = spacing * scaleMultiplier
        let scaledPadding = paddingValue * scaleMultiplier
        let scaledIconSize = iconSize * scaleMultiplier
        let scaledSize = CGSize(
            width: size.width * scaleMultiplier,
            height: size.height * scaleMultiplier
        )
        let scaledCornerRadius = cornerRadius * scaleMultiplier
        let scaledInset = insetAmount * scaleMultiplier
        let scaledStrokeWidth = strokeWidth * scaleMultiplier

        HStack(alignment: .center, spacing: scaledSpacing) {
            comboIcon(for: firstGesture, iconSize: scaledIconSize, alignment: .center)
            comboIcon(for: secondGesture, iconSize: scaledIconSize, alignment: .center)
        }
        .foregroundStyle(resolvedColor)
        .padding(scaledPadding)
        .frame(width: scaledSize.width, height: scaledSize.height, alignment: .center)
        .background(background)
        .cornerRadius(scaledCornerRadius, antialiased: true)
        .overlay(
            RoundedRectangle(cornerRadius: scaledCornerRadius)
                .inset(by: scaledInset)
                .stroke(strokeColor.opacity(isEnabled ? 1 : 0.4), lineWidth: scaledStrokeWidth)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(resolvedAccessibilityLabel)
    }
}

#Preview("Filled") {
    VStack(spacing: 16) {
        ComboPill(firstGesture: .lookUp, secondGesture: .lookRight)
        ComboPill(firstGesture: .lookLeft, secondGesture: .lookDown, foreground: .placeholder)
    }
    .padding()
    .background(Color.boneWhite)
}

#Preview("Outline") {
    VStack(spacing: 16) {
        OutlineComboPill(firstGesture: .lookUp, secondGesture: .lookRight)
        OutlineComboPill(firstGesture: .lookLeft, secondGesture: .lookRight, strokeColor: .placeholder, background: .whiteWhite)
    }
    .padding()
    .background(Color.whiteWhite)
}
