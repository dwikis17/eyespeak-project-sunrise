import SwiftUI
import UIKit

@MainActor
final class KeyboardInputViewModel: ObservableObject {
    @Published var typedText: String = ""
    @Published private(set) var suggestions: [String]
    @Published private(set) var inlinePredictionText: String = ""
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
        typedText
    }
    
    var secondaryHeaderText: String {
        ""
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
    
    var inlinePredictionDisplayText: String {
        guard !inlinePredictionText.isEmpty else { return "" }
        let needsSpace = !(typedText.last?.isWhitespace ?? true)
        return needsSpace ? " " + inlinePredictionText : inlinePredictionText
    }
    
    func applySentencePrediction() {
        let rawPrediction = inlinePredictionText
        let trimmedPrediction = rawPrediction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrediction.isEmpty else { return }
        
        let typedEndsWithSpace = typedText.last?.isWhitespace ?? false
        var insertion = trimmedPrediction
        if typedText.isEmpty || typedEndsWithSpace {
            insertion = trimmedPrediction
        } else if rawPrediction.hasPrefix(" ") {
            insertion = rawPrediction
        } else {
            insertion = " " + trimmedPrediction
        }
        
        typedText.append(insertion)
        
        if let last = typedText.last,
           !last.isWhitespace {
            typedText.append(" ")
        }
        
        inlinePredictionText = ""
        soundPlayer.playModifier()
        refreshSuggestions()
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
            inlinePredictionText = ""
            return
        }
        
        suggestionTask = Task { [weak self] in
            guard let self else { return }
            
            if trimmedText.isEmpty {
                await MainActor.run {
                    self.inlinePredictionText = ""
                    self.suggestions = self.fallbackSuggestions()
                }
                return
            }
            
            if predictionService.isModelAvailable {
                await predictionService.generateSentencePredictions(for: trimmedText)
            } else {
                await predictionService.generateFallbackPredictions(for: trimmedText)
            }
            
            await MainActor.run {
                let prediction = self.predictionService.inlinePrediction
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                self.inlinePredictionText = prediction
                let nextWords = self.nextWordSuggestions(from: prediction)
                self.suggestions = nextWords.isEmpty ? self.fallbackSuggestions() : nextWords
            }
        }
    }
    
    private func fallbackSuggestions() -> [String] {
        let fromPrediction = nextWordSuggestions(from: inlinePredictionText)
        if !fromPrediction.isEmpty {
            return fromPrediction
        }
        return Array(userSuggestionPool.prefix(3))
    }
    
    private func applySuggestion(_ suggestion: String) {
        removeCurrentWordIfNeeded()
        
        if !typedText.isEmpty && !typedText.hasSuffix(" ") {
            typedText.append(" ")
        }
        
        typedText.append(suggestion)
        if !typedText.hasSuffix(" ") {
            typedText.append(" ")
        }
        soundPlayer.playKey()
        refreshSuggestions()
    }
    
    private func removeCurrentWordIfNeeded() {
        guard isInMiddleOfWord(typedText) else { return }
        
        var scalars = typedText.unicodeScalars
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
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

    private func nextWordSuggestions(from prediction: String) -> [String] {
        let trimmed = prediction.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        
        let tokens = trimmed
            .split(whereSeparator: { $0.isWhitespace })
            .map { substring -> String in
                substring
                    .trimmingCharacters(in: .punctuationCharacters)
            }
            .filter { !$0.isEmpty }
        
        var uniqueWords: [String] = []
        for token in tokens {
            let lower = token.lowercased()
            if !uniqueWords.contains(where: { $0.lowercased() == lower }) {
                uniqueWords.append(token)
            }
            if uniqueWords.count == 3 { break }
        }
        return uniqueWords
    }
}
