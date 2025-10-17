import SwiftUI
import UIKit

struct WordPredictionKeyboardView: View {
    @StateObject private var viewModel = KeyboardViewModel()
    
    let letters = ["H", "E", "L", "O", "W"]
    
    var body: some View {
        VStack(spacing: 20) {
            // Text Display
            VStack(alignment: .leading, spacing: 8) {
                Text("Typed Text")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                ScrollView {
                    Text(viewModel.typedText.isEmpty ? "Start typing..." : viewModel.typedText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(uiColor: .systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        )
                }
                .frame(height: 100)
            }
            
            // Predictions View
            if !viewModel.predictions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggestions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.predictions, id: \.self) { prediction in
                                Button(action: {
                                    viewModel.selectPrediction(prediction)
                                }) {
                                    Text(prediction)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(8)
                                }
                                .accessibilityLabel("Suggestion: \(prediction)")
                            }
                        }
                    }
                }
            }
            
            // Letter Buttons
            HStack(spacing: 12) {
                ForEach(letters, id: \.self) { letter in
                    Button(action: {
                        viewModel.addLetter(letter)
                    }) {
                        Text(letter)
                            .font(.system(size: 28, weight: .bold))
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .accessibilityLabel("Letter \(letter)")
                    .accessibilityAddTraits(.isKeyboardKey)
                }
            }
            
            // Control Buttons
            HStack(spacing: 12) {
                Button(action: {
                    viewModel.addSpace()
                }) {
                    Text("SPACE")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.3))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                }
                .accessibilityLabel("Space")
                .accessibilityAddTraits(.isKeyboardKey)
                
                Button(action: {
                    viewModel.deleteLastCharacter()
                }) {
                    HStack {
                        Image(systemName: "delete.left")
                        Text("DELETE")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                .accessibilityLabel("Delete")
                .accessibilityAddTraits(.isKeyboardKey)
            }
            
            Spacer()
        }
        .padding()
    }
}

// ViewModel with UITextChecker integration
class KeyboardViewModel: ObservableObject {
    @Published var typedText: String = ""
    @Published var predictions: [String] = []
    
    private let textChecker = UITextChecker()
    private var currentWord: String = ""
    
    func addLetter(_ letter: String) {
        typedText += letter
        updateCurrentWord()
        fetchPredictions()
    }
    
    func addSpace() {
        typedText += " "
        currentWord = ""
        predictions = []
    }
    
    func deleteLastCharacter() {
        guard !typedText.isEmpty else { return }
        typedText.removeLast()
        updateCurrentWord()
        fetchPredictions()
    }
    
    func selectPrediction(_ prediction: String) {
        // Replace current word with prediction
        let words = typedText.components(separatedBy: " ")
        var newWords = words
        if !newWords.isEmpty {
            newWords[newWords.count - 1] = prediction
        }
        typedText = newWords.joined(separator: " ") + " "
        currentWord = ""
        predictions = []
    }
    
    private func updateCurrentWord() {
        let words = typedText.components(separatedBy: " ")
        currentWord = words.last ?? ""
    }
    
    private func fetchPredictions() {
        guard !currentWord.isEmpty else {
            predictions = []
            return
        }
        
        let range = NSRange(location: 0, length: currentWord.utf16.count)
        
        if let completions = textChecker.completions(
            forPartialWordRange: range,
            in: currentWord,
            language: "en"
        ) {
            // Limit to first 5 predictions
            predictions = Array(completions.prefix(5))
        } else {
            predictions = []
        }
    }
}

// Preview
struct WordPredictionKeyboardView_Previews: PreviewProvider {
    static var previews: some View {
        WordPredictionKeyboardView()
    }
}
