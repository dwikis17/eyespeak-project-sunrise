import Foundation
import Combine
import SwiftUI

/// Lightweight model wrapper for triggering speech from the keyboard.
/// Uses the shared `SpeechService` to speak the current typed text.
final class KeyboardSpeechServiceModel: ObservableObject {
    @Published var isSpeaking: Bool = false
    @Published var lastSpokenText: String = ""

    private let speechService: SpeechService

    init(speechService: SpeechService = .shared) {
        self.speechService = speechService
    }

    /// Speaks the provided text using the shared speech service.
    func speak(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        lastSpokenText = trimmed
        speechService.speak(trimmed)

        // Best-effort visual feedback
        isSpeaking = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isSpeaking = false
        }
    }
}