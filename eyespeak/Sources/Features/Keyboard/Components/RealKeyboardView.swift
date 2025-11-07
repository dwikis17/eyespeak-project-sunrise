import SwiftUI

struct RealKeyboardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                AddWordButtonView()
            }
            .padding(0)
            .frame(maxWidth: .infinity, alignment: .topTrailing)
            // Word Section
            HStack(alignment: .center, spacing: 10) {
                HStack(alignment: .center) {
                    // Space Between
                    HStack(alignment: .center, spacing: 10) {
                        Text("Can I eat a dozen of donut")
                            .font(Font.custom("Montserrat", size: 64))
                            .foregroundColor(.black)
                        VStack(alignment: .leading, spacing: 10) {
                            OutlineComboPill(
                                firstGesture: .lookUp,
                                secondGesture: .lookRight,
                                strokeColor: .placeholder,
                                background: .whiteWhite,
                                iconColor: .placeholder
                            )
                        }
                        .padding(.horizontal, 0)
                        .padding(.top, 31)
                        .padding(.bottom, 0)
                        .frame(minWidth: 39.312, maxWidth: 39.312, maxHeight: .infinity, alignment: .topLeading)
                    }
                    .padding(0)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    //              Spacer()
                    // Alternative Views and Spacers
                    //              View()
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                
                
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 0)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            // Keyboard Section
            VStack(alignment: .trailing, spacing: 7.6044) {
                // first row
                HStack(alignment: .center, spacing: 6.84396) { ... }
                .padding(.horizontal, 7.6044)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                // second row
                HStack(alignment: .center, spacing: 6.84396) { ... }
                .padding(.horizontal, 7.6044)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                // third row
                HStack(alignment: .top, spacing: 6.84396) { ... }
                .padding(.horizontal, 7.6044)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                // fourth row
                HStack(alignment: .top, spacing: 6.84396) { ... }
                .padding(.horizontal, 7.6044)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                // fifth row
                HStack(alignment: .top, spacing: 6.84396) { ... }
                .padding(.horizontal, 7.6044)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .padding(0)
            .frame(maxWidth: .infinity, alignment: .trailing)

        }
        .padding(0)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                
    }
}

#Preview {
    RealKeyboardView()
}
