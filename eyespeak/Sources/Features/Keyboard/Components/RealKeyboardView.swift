import SwiftUI

struct RealKeyboardView: View {
    private let suggestions = ["drink", "eat", "drive"]
    private let topRowLetters = ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p"]
    private let middleRowLetters = ["a", "s", "d", "f", "g", "h", "j", "k", "l"]
    private let bottomRowLetters = ["z", "x", "c", "v", "b", "n", "m"]

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
                HStack(alignment: .center, spacing: 6.84396) {
                    ForEach(suggestions, id: \.self) { word in
                        CompletionKeyView(title: word)
                    }
                }
                .padding(.horizontal, 7.6044)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                // second row (qwerty + icon key)
                HStack(alignment: .center, spacing: 6.84396) {
                    ForEach(topRowLetters, id: \.self) { letter in
                        KeyView(letter: letter)
                    }
                    
                    TrashKeyView()
                }
                .padding(.horizontal, 7.6044)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .trailing)
                
                // third row (asdf... + speaker)
                HStack(alignment: .center, spacing: 6.84396) {
                    ForEach(middleRowLetters, id: \.self) { letter in
                        KeyView(letter: letter)
                    }
                    
                    SpeakKeyView()
                }
                .padding(.horizontal, 7.6044)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                // fourth row (shift + z row)
                HStack(alignment: .center, spacing: 6.84396) {
                    ShiftKeyView()
                    
                    ForEach(bottomRowLetters, id: \.self) { letter in
                        KeyView(letter: letter)
                    }
                }
                .padding(.horizontal, 7.6044)
                .padding(.vertical, 0)
                .frame(maxWidth: .infinity, alignment: .topLeading)
                
                // fifth row (.?123, space, trash)
                HStack(alignment: .center, spacing: 6.84396) {
                    
                    SpaceKeyView()
                    
                    DeleteKeyView()
                }
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
