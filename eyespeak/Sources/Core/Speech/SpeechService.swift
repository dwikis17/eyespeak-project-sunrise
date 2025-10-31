//
//  SpeechService.swift
//  eyespeak
//
//  Centralised text-to-speech helper shared across the AAC experience.
//

import AVFoundation

public final class SpeechService {
    public static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private let queue = DispatchQueue(label: "com.eyespeak.speech", qos: .userInitiated)
    
    private init() {}
    
    public func speak(_ text: String, language: String? = nil, rate: Float = AVSpeechUtteranceDefaultSpeechRate) {
        queue.async { [weak self] in
            guard let self else { return }
            if self.synthesizer.isSpeaking {
                self.synthesizer.stopSpeaking(at: .immediate)
            }
            
            let utterance = AVSpeechUtterance(string: text)
            utterance.rate = rate
            utterance.volume = 0.9
            if let language {
                utterance.voice = AVSpeechSynthesisVoice(language: language)
            }
            self.synthesizer.speak(utterance)
        }
    }
}
