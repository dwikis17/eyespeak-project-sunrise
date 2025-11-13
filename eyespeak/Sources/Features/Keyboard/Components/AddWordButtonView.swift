import SwiftUI

struct AddWordButtonView: View {
    private let firstGesture: GestureType
    private let secondGesture: GestureType
    
    init(
        firstGesture: GestureType = .lookUp,
        secondGesture: GestureType = .lookRight
    ) {
        self.firstGesture = firstGesture
        self.secondGesture = secondGesture
    }
    
    var body: some View {
        let buttonColor = Color.mellowBlue

        return VStack {
            HStack {
                Spacer()
                ComboPill(
                    firstGesture: firstGesture,
                    secondGesture: secondGesture,
                    foreground: buttonColor,
                    background: .whiteWhite
                )
            }

            Spacer()

            Text("ADD WORD TO\nBOARD")
              .font(Typography.boldTitle)
              .foregroundColor(.whiteWhite)
              .multilineTextAlignment(.leading)
              .lineLimit(nil)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(16.67893)
        .frame(width: 203, height: 102, alignment: .center)
        .background(buttonColor)
        .cornerRadius(22.23858)
    }
}

#Preview {
    AddWordButtonView()
        .padding()
        .previewLayout(.sizeThatFits)
}
