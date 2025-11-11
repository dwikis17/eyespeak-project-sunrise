import SwiftUI
import UIKit

struct ShiftKeyView: View {
    private let firstGesture: GestureType
    private let secondGesture: GestureType
    private let backgroundColor = Color(red: 0.87, green: 0.88, blue: 0.93)

    init(
        firstGesture: GestureType = .lookDown,
        secondGesture: GestureType = .lookLeft
    ) {
        self.firstGesture = firstGesture
        self.secondGesture = secondGesture
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            OutlineComboPill(
                firstGesture: firstGesture,
                secondGesture: secondGesture,
                strokeColor: .mellowBlue,
                background: backgroundColor,
                iconColor: .mellowBlue
            )

            Image("shift")
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .foregroundColor(.mellowBlue)
                .frame(height: 32)
                .offset(y: 4)
        }
        .padding(0)
        .frame(width: 125, height: 76, alignment: .center)
        .background(backgroundColor)
        .cornerRadius(5.14114)
    }

}

#Preview {
    ShiftKeyView()
        .padding()
        .background(Color.boneWhite)
}
