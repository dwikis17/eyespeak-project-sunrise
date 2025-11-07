import SwiftUI

struct CompletionKeyView: View {
    private let title: String
    private let firstGesture: GestureType
    private let secondGesture: GestureType
    private let backgroundColor: Color = .blueholder

    init(
        title: String,
        firstGesture: GestureType = .lookUp,
        secondGesture: GestureType = .lookRight
    ) {
        self.title = title
        self.firstGesture = firstGesture
        self.secondGesture = secondGesture
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8.22631) {
            OutlineComboPill(
                firstGesture: firstGesture,
                secondGesture: secondGesture,
                strokeColor: .mellowBlue,
                background: backgroundColor,
                iconColor: .mellowBlue
            )

            Text(title)
                .font(Typography.boldHeader)
                .multilineTextAlignment(.center)
                .foregroundColor(.mellowBlue)
        }
        .padding(.leading, 74.00215)
        .padding(.trailing, 74.79784)
        .padding(.top, 15.61809)
        .padding(.bottom, 9.7723)
        .frame(maxWidth: .infinity, alignment: .bottom)
        .background(backgroundColor)
        .cornerRadius(5.14114)
    }
}

#Preview {
    CompletionKeyView(title: "Completion")
        .padding()
        .background(Color.boneWhite)
}
