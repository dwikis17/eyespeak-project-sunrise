import SwiftUI

struct AddWordButtonView: View {
    var body: some View {
        let brandBlue = Color(red: 0.35, green: 0.42, blue: 0.62)

        return VStack {
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.white)
                    .frame(width: 58, height: 28)
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(brandBlue)
                    )
            }

            Spacer()

            Text("ADD WORD TO\nBOARD")
              .font(
                Font.custom("Montserrat", size: 14)
                  .weight(.bold)
              )
              .foregroundColor(.white)
              .multilineTextAlignment(.leading)
              .lineLimit(nil)
              .fixedSize(horizontal: false, vertical: true)
              .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .padding(16.67893)
        .frame(width: 203, height: 102, alignment: .center)
        .background(brandBlue)
        .cornerRadius(22.23858)
    }
}

#Preview {
    AddWordButtonView()
        .padding()
        .previewLayout(.sizeThatFits)
}

