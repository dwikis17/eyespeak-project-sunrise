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
    private let comboStrokeColor: Color
    private let comboBackgroundColor: Color
    private let comboIconColor: Color?

    init(
        content: Content,
        firstGesture: GestureType = .lookUp,
        secondGesture: GestureType = .lookRight,
        textColor: Color = .mellowBlue,
        backgroundColor: Color = .whiteWhite,
        comboStrokeColor: Color = .placeholder,
        comboBackgroundColor: Color = .whiteWhite,
        comboIconColor: Color? = .placeholder
    ) {
        self.content = content
        self.firstGesture = firstGesture
        self.secondGesture = secondGesture
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        self.comboStrokeColor = comboStrokeColor
        self.comboBackgroundColor = comboBackgroundColor
        self.comboIconColor = comboIconColor
    }

    init(
        letter: String = "q",
        firstGesture: GestureType = .lookUp,
        secondGesture: GestureType = .lookRight,
        textColor: Color = .mellowBlue,
        backgroundColor: Color = .whiteWhite,
        comboStrokeColor: Color = .placeholder,
        comboBackgroundColor: Color = .whiteWhite,
        comboIconColor: Color? = .placeholder
    ) {
        self.init(
            content: .text(letter),
            firstGesture: firstGesture,
            secondGesture: secondGesture,
            textColor: textColor,
            backgroundColor: backgroundColor,
            comboStrokeColor: comboStrokeColor,
            comboBackgroundColor: comboBackgroundColor,
            comboIconColor: comboIconColor
        )
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            OutlineComboPill(
                firstGesture: firstGesture,
                secondGesture: secondGesture,
                strokeColor: comboStrokeColor,
                background: comboBackgroundColor,
                iconColor: comboIconColor
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
