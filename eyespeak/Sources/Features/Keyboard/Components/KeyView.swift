import SwiftUI

struct KeyView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            OutlineComboPill(
                firstGesture: .lookUp,
                secondGesture: .lookRight,
                strokeColor: .placeholder,
                background: .whiteWhite,
                iconColor: .placeholder
            )

            Text("q")
                .font(Typography.keyboardMedium)
                .multilineTextAlignment(.center)
                .foregroundColor(Color(red: 0.34, green: 0.42, blue: 0.62))
        }
        .padding(0)
        .frame(width: 83.3047, height: 75.57471, alignment: .center)
        .background(.white)
        .cornerRadius(5.14114)
    }
}

#Preview {
    KeyView()
        .padding(20)
        .background(Color.boneWhite)
}

