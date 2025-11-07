import SwiftUI

struct SpaceKeyView: View {
    private let firstGesture: GestureType
    private let secondGesture: GestureType

    init(
        firstGesture: GestureType = .lookLeft,
        secondGesture: GestureType = .lookRight
    ) {
        self.firstGesture = firstGesture
        self.secondGesture = secondGesture
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            OutlineComboPill(
                firstGesture: firstGesture,
                secondGesture: secondGesture,
                strokeColor: .mellowBlue,
                background: .whiteWhite,
                iconColor: .mellowBlue
            )
        }
        .padding(.horizontal, 0)
        .padding(.top, 32.24718)
        .padding(.bottom, 26.17283)
        .frame(width: 777.16937, height: 75.28352, alignment: .center)
        .background(Color.whiteWhite)
        .cornerRadius(5.14114)
    }
}

#Preview {
    SpaceKeyView()
        .padding()
        .background(Color.boneWhite)
}
