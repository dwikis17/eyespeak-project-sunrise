import SwiftUI

struct KeyView: View {
    enum Content {
        case text(String)
        case image(image: Image, tint: Color? = nil)
    }

    private let content: Content
    private let firstGesture: GestureType
    private let secondGesture: GestureType
    private let textColor: Color
    private let backgroundColor: Color

    init(
        content: Content,
        firstGesture: GestureType = .lookUp,
        secondGesture: GestureType = .lookRight,
        textColor: Color = .mellowBlue,
        backgroundColor: Color = .whiteWhite
    ) {
        self.content = content
        self.firstGesture = firstGesture
        self.secondGesture = secondGesture
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }

    init(
        letter: String = "q",
        firstGesture: GestureType = .lookUp,
        secondGesture: GestureType = .lookRight,
        textColor: Color = .mellowBlue,
        backgroundColor: Color = .whiteWhite
    ) {
        self.init(
            content: .text(letter),
            firstGesture: firstGesture,
            secondGesture: secondGesture,
            textColor: textColor,
            backgroundColor: backgroundColor
        )
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

            keyContentView
        }
        .padding(0)
        .frame(width: 83.3047, height: 75.57471, alignment: .center)
        .background(backgroundColor)
        .cornerRadius(5.14114)
    }

    @ViewBuilder
    private var keyContentView: some View {
        switch content {
        case let .text(letter):
            Text(letter)
                .font(Typography.keyboardMedium)
                .multilineTextAlignment(.center)
                .foregroundColor(textColor)
                .frame(height: 28, alignment: .center)
        case let .image(image, tint):
            image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
                .offset(y: 4)
                .foregroundColor(tint ?? .mellowBlue)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        KeyView(letter: "a", firstGesture: .lookDown, secondGesture: .lookRight)

        KeyView(
            content: .image(image: Image("trash"), tint: .mellowBlue),
            firstGesture: .lookUp,
            secondGesture: .lookLeft
        )
    }
    .padding(20)
    .background(Color.boneWhite)
}
