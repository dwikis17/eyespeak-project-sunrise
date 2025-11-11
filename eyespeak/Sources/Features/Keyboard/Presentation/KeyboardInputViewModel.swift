import SwiftUI

@MainActor
final class KeyboardInputViewModel: ObservableObject {
    @Published var typedText: String = ""
    @Published var suggestions: [String]
    @Published var isShiftEnabled: Bool = false
    
    private let speechModel: KeyboardSpeechServiceModel
    
    init(
        suggestions: [String] = ["drink", "eat", "drive"],
        speechModel: KeyboardSpeechServiceModel = KeyboardSpeechServiceModel()
    ) {
        self.suggestions = suggestions
        self.speechModel = speechModel
    }
    
    var primaryHeaderText: String {
        typedText.isEmpty ? "Can I " : typedText
    }
    
    var secondaryHeaderText: String {
        typedText.isEmpty ? "eat a dozen of donut" : ""
    }
    
    func insertLetter(_ letter: String) {
        let value = isShiftEnabled ? letter.uppercased() : letter.lowercased()
        typedText.append(value)
        if isShiftEnabled {
            isShiftEnabled = false
        }
    }
    
    func insertSuggestion(at index: Int) {
        guard suggestions.indices.contains(index) else { return }
        if !typedText.isEmpty && !typedText.hasSuffix(" ") {
            typedText.append(" ")
        }
        typedText.append(suggestions[index])
        typedText.append(" ")
    }
    
    func addSpace() {
        typedText.append(" ")
    }
    
    func deleteLast() {
        guard !typedText.isEmpty else { return }
        typedText.removeLast()
    }
    
    func clearAll() {
        typedText.removeAll()
    }
    
    func speakText() {
        speechModel.speak(typedText)
    }
    
    func toggleShift() {
        isShiftEnabled.toggle()
    }
    
    func saveCurrentPhraseToSuggestions() {
        let trimmed = typedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let existingIndex = suggestions.firstIndex(of: trimmed) {
            suggestions.remove(at: existingIndex)
        }
        suggestions.insert(trimmed, at: 0)
        if suggestions.count > 3 {
            suggestions = Array(suggestions.prefix(3))
        }
    }
    
    func displayLetter(for letter: String) -> String {
        isShiftEnabled ? letter.uppercased() : letter.lowercased()
    }
}
