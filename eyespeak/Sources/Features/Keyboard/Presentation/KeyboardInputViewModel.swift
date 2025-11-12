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
    private let quickTypeService = QuickTypePredictionService()
    private let soundPlayer: KeyboardSoundPlayer
    private let textChecker = UITextChecker()
    private let defaultPredictiveWords = ["I", "You", "We"]
    private var userSuggestionPool: [String]
    private var quickTypeTask: Task<Void, Never>?
    private var sentenceTask: Task<Void, Never>?
    
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
        quickTypeTask?.cancel()
        sentenceTask?.cancel()
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
        learnFromCurrentText()
    }
    
    private func refreshSuggestions() {
        quickTypeTask?.cancel()
        sentenceTask?.cancel()
        
        let workingText = typedText
        let trimmedText = workingText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if isInMiddleOfWord(workingText) {
            let current = currentWord(from: workingText)
            let completions = wordCompletions(for: current)
            let resolved = completions.isEmpty ? predictionFallbacks() : Array(completions.prefix(3))
            suggestions = resolved
            inlinePredictionText = ""
            return
        }
        
        quickTypeTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: 75_000_000) // ~75 ms debounce
            if Task.isCancelled { return }
            let predictions = await self.quickTypeService.predictions(for: workingText)
            let fallback = self.predictionFallbacks()
            let resolved = predictions.isEmpty ? fallback : Array(predictions.prefix(3))
            await MainActor.run {
                self.suggestions = resolved
            }
        }
        
        guard !trimmedText.isEmpty else {
            inlinePredictionText = ""
            return
        }
        
        sentenceTask = Task { [weak self] in
            guard let self else { return }
            if self.predictionService.isModelAvailable {
                await self.predictionService.generateSentencePredictions(for: workingText)
            } else {
                await self.predictionService.generateFallbackPredictions(for: workingText)
            }
            if Task.isCancelled { return }
            await MainActor.run {
                let prediction = self.predictionService.inlinePrediction
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                self.inlinePredictionText = prediction
            }
        }
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
        learnFromCurrentText()
    }
    
    private func learnFromCurrentText() {
        let snapshot = typedText
        guard !snapshot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        Task {
            await quickTypeService.learn(from: snapshot)
        }
    }
    
    private func predictionFallbacks() -> [String] {
        if userSuggestionPool.isEmpty {
            return Array(defaultPredictiveWords.prefix(3))
        }
        return Array(userSuggestionPool.prefix(3))
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
        let nsWord = word as NSString
        let range = NSRange(location: 0, length: nsWord.length)
        let language = Locale.preferredLanguages.first ?? "en_US"
        guard let completions = textChecker.completions(
            forPartialWordRange: range,
            in: word,
            language: language
        ) else {
            return []
        }
        return completions
    }
}
