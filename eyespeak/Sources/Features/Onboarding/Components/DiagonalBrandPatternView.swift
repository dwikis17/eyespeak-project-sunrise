import SwiftUI

struct DiagonalBrandPatternView: View {
    var text: String = "EYESPEAK"
    
    var body: some View {
        let brandGradient = LinearGradient(
            gradient: Gradient(colors: [
                Color(hex: "#E63946")!,
                Color(hex: "#F77F00")!
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        
        ZStack {
            Rectangle().fill(brandGradient)
            
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                
                Canvas { context, size in
                    // Calculate diagonal coverage
                    let diagonal = sqrt(size.width * size.width + size.height * size.height)
                    let fontSize: CGFloat = 200  // ← Slightly larger
                    let rowHeight: CGFloat = 200  // ← More spacing between rows
                    let speed: CGFloat = 50
                    
                    // Move to center and rotate
                    context.translateBy(x: size.width / 2, y: size.height / 2)
                    context.rotate(by: .degrees(-45))
                    context.translateBy(x: -diagonal / 2, y: -diagonal / 2)
                    
                    // Draw rows
                    let numRows = Int(diagonal / rowHeight) + 4
                    for row in 0..<numRows {
                        let y = CGFloat(row) * rowHeight + 70
                        let direction: CGFloat = row % 2 == 0 ? 1 : -1
                        let offset = (CGFloat(t) * speed * direction).truncatingRemainder(dividingBy: 400)
                        
                        var x = offset - 400
                        while x < diagonal + 400 {
                            // Create condensed text by scaling horizontally
                            var textContext = context
                            textContext.scaleBy(x: 0.85, y: 1.0)  // ← Condense horizontally
                            textContext.draw(
                                Text(text)
                                    .font(.system(size: fontSize, weight: .black))
                                    .foregroundColor(.white),
                                at: CGPoint(x: x / 0.85, y: y)  // ← Adjust x for scaling
                            )
                            x += 900  // ← Spacing between words
                        }
                    }
                }
            }
        }
        .clipped()
    }
}

#Preview("Diagonal Brand Pattern") {
    DiagonalBrandPatternView()
        .frame(width: 320, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding()
}
