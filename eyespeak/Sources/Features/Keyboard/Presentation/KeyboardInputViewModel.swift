import SwiftUI
import UIKit

@MainActor
final class KeyboardInputViewModel: ObservableObject {
    @Published var typedText: String = ""
    @Published private(set) var suggestions: [String]
    @Published var isShiftEnabled: Bool = false
    
    private let speechModel: KeyboardSpeechServiceModel
    private let predictionService: SentencePredictionService
    private let soundPlayer: KeyboardSoundPlayer
    private let textChecker = UITextChecker()
    private var userSuggestionPool: [String]
    private var suggestionTask: Task<Void, Never>?
    
    init(
        suggestions: [String] = ["drink", "eat", "drive"],
        speechModel: KeyboardSpeechServiceModel = KeyboardSpeechServiceModel(),
        predictionService: SentencePredictionService? = nil,
        soundPlayer: KeyboardSoundPlayer? = nil
    ) {
        self.speechModel = speechModel
        self.predictionService = predictionService ?? SentencePredictionService()
        self.soundPlayer = soundPlayer ?? KeyboardSoundPlayer()
        self.userSuggestionPool = suggestions
        self.suggestions = Array(suggestions.prefix(3))
        refreshSuggestions()
    }
    
    deinit {
        suggestionTask?.cancel()
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
        soundPlayer.playKey()
        refreshSuggestions()
    }
    
    func insertSuggestion(at index: Int) {
        guard suggestions.indices.contains(index) else { return }
        applySuggestion(suggestions[index])
    }
    
    func addSpace() {
        typedText.append(" ")
        soundPlayer.playKey()
        refreshSuggestions()
    }
    
    func deleteLast() {
        guard !typedText.isEmpty else { return }
        typedText.removeLast()
        soundPlayer.playDelete()
        refreshSuggestions()
    }
    
    func clearAll() {
        guard !typedText.isEmpty else { return }
        typedText.removeAll()
        soundPlayer.playDelete()
        refreshSuggestions()
    }
    
    func speakText() {
        speechModel.speak(typedText)
    }
    
    func toggleShift() {
        isShiftEnabled.toggle()
        soundPlayer.playModifier()
    }
    
    func saveCurrentPhraseToSuggestions() {
        let trimmed = typedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        if let existingIndex = userSuggestionPool.firstIndex(of: trimmed) {
            userSuggestionPool.remove(at: existingIndex)
        }
        userSuggestionPool.insert(trimmed, at: 0)
        if userSuggestionPool.count > 3 {
            userSuggestionPool = Array(userSuggestionPool.prefix(3))
        }
        refreshSuggestions()
    }
    
    func displayLetter(for letter: String) -> String {
        isShiftEnabled ? letter.uppercased() : letter.lowercased()
    }
    
    private func refreshSuggestions() {
        suggestionTask?.cancel()
        let workingText = typedText
        let trimmedText = workingText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isInMiddleOfWord(workingText) {
            let currentWord = currentWord(from: workingText)
            let completions = wordCompletions(for: currentWord)
            if completions.isEmpty {
                suggestions = fallbackSuggestions()
            } else {
                suggestions = Array(completions.prefix(3))
            }
            return
        }
        
        suggestionTask = Task { [weak self] in
            guard let self else { return }
            
            if trimmedText.isEmpty {
                suggestions = fallbackSuggestions()
                return
            }
            
            if predictionService.isModelAvailable {
                await predictionService.generateSentencePredictions(for: trimmedText)
            } else {
                await predictionService.generateFallbackPredictions(for: trimmedText)
            }
            
            let predictions = predictionService.sentencePredictions
            if predictions.isEmpty {
                suggestions = fallbackSuggestions()
            } else {
                suggestions = Array(predictions.prefix(3))
            }
        }
    }
    
    private func fallbackSuggestions() -> [String] {
        Array(userSuggestionPool.prefix(3))
    }
    
    private func applySuggestion(_ suggestion: String) {
        removeCurrentWordIfNeeded()
        
        if !typedText.isEmpty && !typedText.hasSuffix(" ") {
            typedText.append(" ")
        }
        
        typedText.append(suggestion)
        typedText.append(" ")
        soundPlayer.playKey()
        refreshSuggestions()
    }
    
    private func removeCurrentWordIfNeeded() {
        guard let lastScalar = typedText.unicodeScalars.last else { return }
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        guard !separators.contains(lastScalar) else { return }
        
        var scalars = typedText.unicodeScalars
        while let currentLast = scalars.last,
              !separators.contains(currentLast) {
            scalars.removeLast()
        }
        
        typedText = String(String.UnicodeScalarView(scalars))
    }
    
    private func isInMiddleOfWord(_ text: String) -> Bool {
        guard let lastScalar = text.unicodeScalars.last else { return false }
        return !CharacterSet.whitespacesAndNewlines.contains(lastScalar) &&
            !CharacterSet.punctuationCharacters.contains(lastScalar)
    }
    
    private func currentWord(from text: String) -> String {
        guard !text.isEmpty else { return "" }
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let components = text.components(separatedBy: separators)
        return components.last ?? ""
    }
    
    private func wordCompletions(for word: String) -> [String] {
        guard !word.isEmpty else { return [] }
        let range = NSRange(location: 0, length: word.utf16.count)
        if let completions = textChecker.completions(
            forPartialWordRange: range,
            in: word,
            language: Locale.preferredLanguages.first ?? "en_US"
        ) {
            return completions
        }
        return []
    }
}
