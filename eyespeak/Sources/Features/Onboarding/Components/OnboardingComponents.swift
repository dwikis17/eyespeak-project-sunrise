import SwiftUI

// Shared components for onboarding screens to ease debugging and reuse.

struct OnboardingCardContainer<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(spacing: 16) { content }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
            )
    }
}

struct WelcomeHeaderView: View {
    var title: String
    var subtitle: String
    var alignment: HorizontalAlignment = .leading
    var titleSize: CGFloat = 44
    var subtitleSize: CGFloat = 24
    var body: some View {
        VStack(alignment: alignment, spacing: 10) {
            Text(title)
                .font(Typography.boldHeaderJumbo)
                .foregroundStyle(LinearGradient.redOrange)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
            Text(subtitle)
                .font(Typography.boldHeaderLarge)
                .foregroundColor(.black)
                .multilineTextAlignment(alignment == .center ? .center : .leading)
        }
    }
}

struct ProgressDotsView: View {
    var current: Int
    var total: Int
    var dotSize: CGFloat = 12
    var spacing: CGFloat = 8
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<total) { idx in
                Circle()
                    .fill(idx == current ? Color(.systemGray) : Color(.systemGray4))
                    .frame(width: dotSize, height: dotSize)
            }
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

struct BlinkHoldCTAView: View {
    var title: String = "Blink and hold to continue"
    var action: () -> Void
    var progress: CGFloat? = nil
    var background: Color = Color(.systemGray5)
    var progressColor: Color = .energeticOrange
    var foreground: Color = .black
    var cornerRadius: CGFloat = 15
    var height: CGFloat = 96
    var textSize: CGFloat = 18
    var iconSize: CGFloat = 20

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "eye")
                    .font(.system(size: iconSize, weight: .semibold))
                Text(title)
                    .font(Typography.boldHeader)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(foreground)
            .background(progressBackground)
            .frame(maxWidth: .infinity)
            .frame(height: height)
        }
        .accessibilityHint("Simulate blink-and-hold during debugging")
    }

    private var progressBackground: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(background)
                if let progress = progress {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(progressColor)
                        .frame(width: width * max(0, min(1, progress)))
                        .animation(.easeInOut(duration: 0.05), value: progress)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

// DiagonalBrandPatternView moved to its own file (Components/DiagonalBrandPatternView.swift)

struct OnboardingInfoTile: View {
    var icon: String
    var title: String
    var subtitle: String
    var isEnabled: Bool = true
    var isSelected: Bool = false
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient.redOrange)
                    .frame(width: 42, height: 42)
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.system(size: 18, weight: .bold))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isEnabled ? .green : .gray.opacity(0.6))
                .font(.system(size: 18, weight: .semibold))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(LinearGradient.redOrange, lineWidth: 2)
                .opacity(isSelected ? 1 : 0)
        )
    }
}

// MARK: - Previews

#Preview("Onboarding Card Container") {
    OnboardingCardContainer {
        VStack(alignment: .leading, spacing: 12) {
            WelcomeHeaderView(title: "Welcome!", subtitle: "Let's set up your app")
            Text("This will only take a minute").foregroundStyle(.secondary)
            ProgressDotsView(current: 1, total: 3)
            BlinkHoldCTAView(title: "Blink and hold to select") {}
        }
    }
    .padding()
}

#Preview("Welcome Header + Progress") {
    VStack(alignment: .leading, spacing: 16) {
        WelcomeHeaderView(title: "First Time Setup", subtitle: "We need to learn about you")
        ProgressDotsView(current: 0, total: 3)
    }
    .padding()
}

#Preview("Info Tile List") {
    VStack(spacing: 12) {
        OnboardingInfoTile(icon: "arrow.right", title: "Look Right", subtitle: "Look away from the screen toward your right side")
        OnboardingInfoTile(icon: "arrow.left", title: "Look Left", subtitle: "Look away from the screen toward your left side")
        OnboardingInfoTile(icon: "arrow.up", title: "Look Up", subtitle: "Look away from the screen toward your up side", isEnabled: false)
    }
    .padding()
    .frame(maxWidth: 360)
}

#Preview("Blink CTA Variants") {
    VStack(spacing: 16) {
        BlinkHoldCTAView(title: "Blink and hold to continue") {}
        BlinkHoldCTAView(title: "Blink to confirm") {}
    }
    .padding()
    .frame(maxWidth: 420)
}

#Preview("Brand Pattern") {
    DiagonalBrandPatternView()
        .frame(width: 320, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding()
}
