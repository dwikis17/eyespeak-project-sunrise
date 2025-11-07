import SwiftUI

struct KeyView: View {
    let letter: String
    let firstGesture: GestureType
    let secondGesture: GestureType

    init(
        letter: String = "q",
        firstGesture: GestureType = .lookUp,
        secondGesture: GestureType = .lookRight
    ) {
        self.letter = letter
        self.firstGesture = firstGesture d
        self.secondGesture = secondGesture
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            OutlineComboPill(
                firstGesture: firstGesture,
                secondGesture: secondGesture,
                strokeColor: .placeholder,
                background: .whiteWhite,
                iconColor: .placeholder
            )

            Text(letter)
                .font(Typography.keyboardMedium)
                .multilineTextAlignment(.center)
                .foregroundColor(.mellowBlue)
        }
        .padding(0)
        .frame(width: 83.3047, height: 75.57471, alignment: .center)
        .background(.white)
        .cornerRadius(5.14114)
    }
}

#Preview {
    KeyView(letter: "a", firstGesture: .lookDown, secondGesture: .lookRight)
        .padding(20)
        .background(Color.boneWhite)
}
