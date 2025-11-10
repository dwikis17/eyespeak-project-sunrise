import SwiftUI

struct DeleteKeyView: View {
    private let firstGesture: GestureType
    private let secondGesture: GestureType

    init(
        firstGesture: GestureType = .lookUp,
        secondGesture: GestureType = .lookRight
    ) {
        self.firstGesture = firstGesture
        self.secondGesture = secondGesture
    }

    private enum Layout {
        static let keyHeight: CGFloat = 75.57471
        static let contentSpacing: CGFloat = 10
        static let backgroundColor = Color(red: 0.87, green: 0.88, blue: 0.93)
    }

    var body: some View {
        VStack(alignment: .center, spacing: Layout.contentSpacing) {
            OutlineComboPill(
                firstGesture: firstGesture,
                secondGesture: secondGesture,
                strokeColor: .mellowBlue,
                background: Layout.backgroundColor,
                iconColor: .mellowBlue
            )

            Image("delete")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 20)
                .foregroundColor(.mellowBlue)
        }
        .frame(maxWidth: .infinity, minHeight: Layout.keyHeight, maxHeight: Layout.keyHeight)
        .background(Layout.backgroundColor)
        .cornerRadius(6.68328)
        .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 2)
    }
}

#Preview {
    DeleteKeyView()
        .padding()
        .background(Color.boneWhite)
}
