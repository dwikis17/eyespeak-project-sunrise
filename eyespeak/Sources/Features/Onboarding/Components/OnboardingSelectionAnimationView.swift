import SwiftUI

// Simple demo animation: an orange selection rectangle moves down the tiles
// and toggles the trailing checkmark. This is standalone with a preview.

struct OnboardingSelectionAnimationView: View {
    // Demo content
    private let steps: [(icon: String, title: String, subtitle: String)] = [
        ("arrow.right", "Look Right", "Look away from the screen toward your right side"),
        ("arrow.left", "Look Left", "Look away from the screen toward your left side"),
        ("arrow.up", "Look Up", "Look away from the screen toward your up side")
    ]

    // Animation state
    @State private var selectedIndex: Int = 0
    @State private var checked: Set<Int> = []
    @State private var precheckIndex: Int? = nil
    @State private var animationTimer: Timer?
    @State private var pendingCheckWorkItem: DispatchWorkItem?

    // Layout constants to keep math simple and consistent
    private let containerWidth: CGFloat = 380
    private let containerPadding: CGFloat = 24
    private let tileHeight: CGFloat = 84
    private let tileSpacing: CGFloat = 14

    var body: some View {
        ZStack {
            // Soft container background filling available height
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.systemGroupedBackground))
                .frame(width: containerWidth)
                .frame(maxHeight: .infinity)

            // Vertically center the tiles within the container
            VStack {
                Spacer(minLength: 0)
                VStack(spacing: tileSpacing) {
                    ForEach(steps.indices, id: \..self) { idx in
                        DemoTileView(
                            icon: steps[idx].icon,
                            title: steps[idx].title,
                            subtitle: steps[idx].subtitle,
                            isChecked: checked.contains(idx),
                            isPrechecking: (precheckIndex == idx),
                            isSelected: (selectedIndex == idx)
                        )
                        .frame(height: tileHeight)
                    }
                }
                .padding(containerPadding)
                .frame(width: containerWidth)
                Spacer(minLength: 0)
            }
        }
        .frame(maxHeight: .infinity, alignment: .center)
        .padding(40)
        .background(Color(.systemBackground))
        .onAppear {
            // Drive animation with a device-safe scheduled timer
            startAnimationTimer()
        }
        .onDisappear {
            stopAnimationTimer()
        }
    }

    private func selectionOffsetY(for index: Int) -> CGFloat {
        let step = CGFloat(index)
        return containerPadding + step * (tileHeight + tileSpacing)
    }
}

// MARK: - Timer Driving
private extension OnboardingSelectionAnimationView {
    func startAnimationTimer() {
        stopAnimationTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            advanceCycle()
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }

    func stopAnimationTimer() {
        animationTimer?.invalidate()
        animationTimer = nil
        pendingCheckWorkItem?.cancel()
        pendingCheckWorkItem = nil
    }

    func advanceCycle() {
        // Advance selection and precheck only indices 1 and 2 (not 0)
        let next = (selectedIndex + 1) % steps.count
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            selectedIndex = next
            precheckIndex = (next == 0) ? nil : next
        }
        // When cycle restarts to the first tile, clear all checkmarks
        if next == 0 {
            withAnimation(.easeInOut(duration: 0.25)) { checked.removeAll() }
        }
        // Cancel any pending check animations
        pendingCheckWorkItem?.cancel()
        // Simulate "checking" after a slightly longer pre-check, for 1 and 2 only
        let work = DispatchWorkItem { [next] in
            if next != 0 {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                    checked.insert(next)
                    precheckIndex = nil
                }
            } else {
                precheckIndex = nil
            }
        }
        pendingCheckWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6, execute: work)
    }
}

// MARK: - Demo Tile (simplified styling to match production tiles)
private struct DemoTileView: View {
    let icon: String
    let title: String
    let subtitle: String
    let isChecked: Bool
    let isPrechecking: Bool
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 14) {
            // Gradient icon block
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(LinearGradient.redOrange)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Trailing check indicator
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 24, height: 24)
                if isChecked {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 24, height: 24)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isPrechecking ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(isPrechecking ? 0.08 : 0.05), radius: isPrechecking ? 10 : 6, x: 0, y: isPrechecking ? 6 : 3)
        )
        // Orange stroke attached to this tile's bounds for perfect alignment
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(LinearGradient.redOrange, lineWidth: isSelected ? 3 : 0)
                .shadow(
                    color: Color.orange.opacity(isPrechecking ? 0.35 : 0.0),
                    radius: isPrechecking ? 12 : 0,
                    x: 0,
                    y: isPrechecking ? 8 : 0
                )
                .scaleEffect(isPrechecking ? 1.05 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPrechecking)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isSelected)
        )
        .scaleEffect(isPrechecking ? 1.03 : 1.0)
        .offset(y: isPrechecking ? -2 : 0)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPrechecking)
    }
}

#Preview {
    OnboardingSelectionAnimationView()
        .frame(width: 520, height: 420)
}
