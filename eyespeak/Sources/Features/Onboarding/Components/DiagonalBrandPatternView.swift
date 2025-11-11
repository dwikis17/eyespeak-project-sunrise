import SwiftUI

/// Diagonal brand pattern view with repeating "EYESPEAK " word units.
/// - Visuals: white bold condensed sans-serif over a red→orange gradient.
/// - Layout: multiple parallel diagonal rows, rotated 45°.
/// - Animation: odd rows scroll right, even rows scroll left; infinite tiling.
struct DiagonalBrandPatternView: View {
    var text: String = "EYESPEAK"
    // Helper builds the diagonal rows for the given frame/time.
    @ViewBuilder
    private func renderRows(size: CGFloat, base: CGFloat, t: CGFloat, textUnit: String) -> some View {
        let speed: CGFloat = 55
        // Make words readable and avoid overlap across rows
        let fontSize: CGFloat = max(32, min(base * 0.24, 100))
        // Increase spacing to fully separate rows
        let rowSpacing: CGFloat = fontSize * 0.35
        let rowCount: Int = max(6, Int(ceil((size * 2.0) / (fontSize * 0.95))))
        let colRepeat: Int = max(6, Int(ceil((size * 2.0) / (fontSize * 0.95))))

        VStack(spacing: rowSpacing) {
            ForEach(Array(0..<rowCount), id: \.self) { (row: Int) in
                let direction: CGFloat = row % 2 == 0 ? 1 : -1
                let baseOffset = t * speed * direction
                let loopWidth = size * 1.8

                let contentString = String(repeating: textUnit, count: colRepeat)
                let rowText = Text(contentString)
                    .font(.system(size: fontSize, weight: .heavy))
                    .foregroundColor(.white)
                    .tracking(0)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.vertical, fontSize * 0.06)

                ZStack {
                    rowText.offset(x: baseOffset.truncatingRemainder(dividingBy: loopWidth))
                    rowText.offset(x: baseOffset.truncatingRemainder(dividingBy: loopWidth) - loopWidth)
                    rowText.offset(x: baseOffset.truncatingRemainder(dividingBy: loopWidth) + loopWidth)
                }
            }
        }
        .rotationEffect(.degrees(-45))
        .frame(width: size * 2.0, height: size * 2.0)
        .clipped()
    }
    var body: some View {
        GeometryReader { geo in
            let size = max(geo.size.width, geo.size.height)
            // Custom red→orange gradient
            let brandGradient = LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "#E63946")!,
                    Color(hex: "#F77F00")!
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            // Repeat the word with NO space to achieve continuous tiling: "EYESPEAKEYESPEAK..."
            let textUnit = text

            ZStack {
                Rectangle().fill(brandGradient)

                TimelineView(.animation) { context in
                    let t = CGFloat(context.date.timeIntervalSinceReferenceDate)
                    let base = min(geo.size.width, geo.size.height)
                    renderRows(size: size, base: base, t: t, textUnit: textUnit)
                }
            }
        }
    }
}

#Preview("Diagonal Brand Pattern") {
    DiagonalBrandPatternView()
        .frame(width: 320, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding()
}