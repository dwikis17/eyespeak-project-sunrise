import SwiftUI

struct SpeakKeyView: View {
    private let firstGesture: GestureType
    private let secondGesture: GestureType

    init(
        firstGesture: GestureType = .lookDown,
        secondGesture: GestureType = .lookRight
    ) {
        self.firstGesture = firstGesture
        self.secondGesture = secondGesture
    }

    var body: some View {
        VStack(alignment: .center, spacing: 9.88572) {
            OutlineComboPill(
                firstGesture: firstGesture,
                secondGesture: secondGesture,
                strokeColor: .whiteWhite,
                background: .mellowBlue,
                iconColor: .whiteWhite
            ).padding(.bottom, -4)

            Image("speaker")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .foregroundColor(.whiteWhite)
                .frame(height: 32)
        }
        .padding(.horizontal, 76.12002)
        .padding(.vertical, 43.49715)
        .frame(maxWidth: .infinity, minHeight: 75.57249, maxHeight: 75.57249, alignment: .center)
        .background(Color.mellowBlue)
        .cornerRadius(6.68328)
        .shadow(color: .black.opacity(0.22), radius: 0, x: 0, y: 2.00498)
    }
}

#Preview {
    SpeakKeyView()
        .padding()
        .background(Color.boneWhite)
}
