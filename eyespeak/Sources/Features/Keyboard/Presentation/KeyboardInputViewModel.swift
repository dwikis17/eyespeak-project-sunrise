import SwiftUI

@MainActor
final class KeyboardInputViewModel: ObservableObject {
    @Published var typedText: String = ""
    @Published private(set) var suggestions: [String]
    @Published var isShiftEnabled: Bool = false
    
    private let speechModel: KeyboardSpeechServiceModel
    private let predictionService: SentencePredictionService
    private let soundPlayer: KeyboardSoundPlayer
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
        if !typedText.isEmpty && !typedText.hasSuffix(" ") {
            typedText.append(" ")
        }
        typedText.append(suggestions[index])
        typedText.append(" ")
        soundPlayer.playKey()
        refreshSuggestions()
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
        let currentText = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        suggestionTask = Task { [weak self] in
            guard let self else { return }
            
            if currentText.isEmpty {
                suggestions = Array(userSuggestionPool.prefix(3))
                return
            }
            
            if predictionService.isModelAvailable {
                await predictionService.generateSentencePredictions(for: currentText)
            } else {
                await predictionService.generateFallbackPredictions(for: currentText)
            }
            
            let predictions = predictionService.sentencePredictions
            if predictions.isEmpty {
                suggestions = Array(userSuggestionPool.prefix(3))
            } else {
                suggestions = Array(predictions.prefix(3))
            }
        }
    }
}
