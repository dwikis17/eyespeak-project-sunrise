//
//  SentencePredictionService.swift
//  eyespeak
//
//  Extracted from KeyboardView.swift to simplify debugging and separation
//

import Foundation
import Combine

#if canImport(FoundationModels)
import FoundationModels
#endif

@MainActor
class SentencePredictionService: ObservableObject {
    #if canImport(FoundationModels)
    private var systemModel: SystemLanguageModel?
    private static let sessionInstructions = """
    You speak on behalf of the user—an individual with limited mobility who relies on this device to talk.
    Continue the user’s current sentence in their own voice. Never ask how you can help, never refer to yourself, and never repeat the user’s text.
    Return one concise continuation that keeps their tense, tone, and intent.
    
    User: "hi mom"
    You: "I’m so glad you’re here."
    
    User: "I need"
    You: "another blanket please, I’m chilly."
    
    User: "thank you"
    You: "for helping me today."
    """
    #endif
    private var lastErrorTime: Date?
    private var errorCount = 0
    
    @Published var isModelAvailable = false
    @Published var sentencePredictions: [String] = []
    @Published var inlinePrediction: String = ""
    @Published var debugInfo: String = ""
    
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 1.0
    private let assistantToneMarkers = [
        "how can i assist",
        "how may i assist",
        "how can i help",
        "how may i help",
        "assist you today",
        "let me know how i can help",
        "how can i support",
        "i can help you",
        "i am here to help"
    ]
    
    init() {
        checkModelAvailability()
    }
    
    private func checkModelAvailability() {
        guard #available(iOS 18.1, *) else {
            print("FoundationModels requires iOS 18.1 or later")
            isModelAvailable = false
            debugInfo = "Apple Intelligence requires iOS 18.1+"
            return
        }
        
        #if canImport(FoundationModels)
        systemModel = SystemLanguageModel.default
        
        guard let model = systemModel else {
            print("SystemLanguageModel not available")
            isModelAvailable = false
            debugInfo = "SystemLanguageModel unavailable"
            return
        }
        
        switch model.availability {
        case .available:
            print("✅ Apple Intelligence model available")
            isModelAvailable = true
            debugInfo = "Apple Intelligence: available"
        case .unavailable(.deviceNotEligible):
            print("❌ Device not eligible for Apple Intelligence")
            isModelAvailable = false
            debugInfo = "Device not eligible for Apple Intelligence"
        case .unavailable(.appleIntelligenceNotEnabled):
            print("❌ Apple Intelligence not enabled - check Settings > Apple Intelligence & Siri")
            isModelAvailable = false
            debugInfo = "Enable Apple Intelligence in Settings"
        case .unavailable(.modelNotReady):
            print("⏳ Model is downloading or not ready - try again later")
            isModelAvailable = false
            debugInfo = "Apple Intelligence model not ready"
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                checkModelAvailability()
            }
        case .unavailable(let other):
            print("❌ Model unavailable: \(other)")
            isModelAvailable = false
            debugInfo = "Model unavailable: \(other)"
        }
        #else
        print("FoundationModels framework not available")
        isModelAvailable = false
        debugInfo = "FoundationModels not available"
        #endif
    }
    
    func generateSentencePredictions(for text: String) async {
        #if canImport(FoundationModels)
        guard isModelAvailable,
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !shouldRateLimit() else {
            await MainActor.run {
                self.sentencePredictions = []
                self.inlinePrediction = ""
            }
            return
        }

        let trimmed = sanitizeInput(text)
        // Throttle requests to avoid rapid-fire calls
        let now = Date()
        if let last = lastRequestTime, now.timeIntervalSince(last) < minRequestInterval {
            return
        }
        lastRequestTime = now

        do {
            let prediction = try await requestPrediction(for: trimmed)
            let debugLabel: String
            if prediction.isEmpty {
                debugLabel = "AI: empty"
            } else if isAssistantTone(prediction) {
                logAssistantToneDetection(input: trimmed, prediction: prediction)
                debugLabel = "AI: assistant"
            } else {
                debugLabel = "AI: completion"
            }
            
            let single = prediction.isEmpty ? [] : [prediction]
            await MainActor.run {
                self.sentencePredictions = single
                self.inlinePrediction = prediction
                self.debugInfo = debugLabel
            }
            if !prediction.isEmpty {
                resetErrorCount()
            }
        } catch {
            recordError()
            await logGuardrailFeedback(for: trimmed, error: error)
            await MainActor.run {
                self.sentencePredictions = []
                self.inlinePrediction = ""
                self.debugInfo = "AI error"
            }
        }
        #else
        await MainActor.run {
            self.sentencePredictions = []
            self.inlinePrediction = ""
        }
        #endif
    }
    
    private func normalizeCompletion(_ text: String) -> String {
        var completion = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !completion.isEmpty else { return "" }
        if let last = completion.last,
           !"?!.".contains(last) {
            completion.append(".")
        }
        return completion
    }
    private func sanitizeInput(_ text: String) -> String {
        var sanitized = text
        sanitized = sanitized.replacingOccurrences(of: "(.{1,3})\\1{3,}", with: "$1$1", options: .regularExpression)
        if sanitized.count > 200 {
            sanitized = String(sanitized.prefix(200))
        }
        let sensitivePatterns = [
            "password",
            "credit card",
            "social security",
            "ssn",
            "bank account"
        ]
        for pattern in sensitivePatterns {
            sanitized = sanitized.replacingOccurrences(
                of: pattern,
                with: "[redacted]",
                options: [.caseInsensitive]
            )
        }
        return sanitized.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func logGuardrailFeedback(for text: String, error: Any) async {
        #if canImport(FoundationModels)
        if let generationError = error as? LanguageModelSession.GenerationError,
           case .guardrailViolation = generationError {
            print("Guardrail may have been triggered incorrectly for text: '\(text)'")
            print("Consider filing feedback at https://feedbackassistant.apple.com")
        }
        #endif
    }
    
    private func shouldRateLimit() -> Bool {
        guard let lastErrorTime = lastErrorTime else { return false }
        let timeSinceError = Date().timeIntervalSince(lastErrorTime)
        return timeSinceError < 5.0 && errorCount >= 3
    }
    
    private func recordError() {
        lastErrorTime = Date()
        errorCount += 1
    }
    
    private func resetErrorCount() {
        errorCount = 0
        lastErrorTime = nil
    }
    
    #if canImport(FoundationModels)
    private func requestPrediction(for text: String) async throws -> String {
        let session = try LanguageModelSession(instructions: Self.sessionInstructions)
        let prompt = prompt(for: text)
        let response = try await session.respond(to: prompt)
        let parsed = parseCompletions(from: response.content, originalText: text)
        let normalized = parsed
            .map { self.normalizeCompletion($0) }
            .filter { !$0.isEmpty }
        return normalized.first ?? ""
    }
    #endif
    
    private func prompt(for text: String) -> String {
        """
        You are speaking on behalf of the user. Continue their sentence as a first-person statement without greeting them, offering assistance, or referring to yourself.
        Reply with one natural continuation only and do not repeat the user's words.
        
        USER TEXT:
        \(text)
        """
    }
    
    private func isAssistantTone(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        let normalized = text.lowercased()
        return assistantToneMarkers.contains { normalized.contains($0) }
    }
    
    private func logAssistantToneDetection(input: String, prediction: String) {
        print("⚠️ SentencePredictionService detected assistant-style completion.")
        print("Input: '\(input)'")
        print("Prediction: '\(prediction)'")
        print("⚠️ Output shown to user for awareness.\n")
    }
    
    private func parseCompletions(from content: String, originalText: String) -> [String] {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let rejectionPatterns = [
            "i can't assist",
            "i cannot help",
            "i'm sorry",
            "unable to assist",
            "cannot provide"
        ]
        let lowercaseContent = trimmed.lowercased()
        for pattern in rejectionPatterns where lowercaseContent.contains(pattern) {
            return []
        }
        
        var cleanLine = trimmed
        if let newline = cleanLine.firstIndex(of: "\n") {
            cleanLine = String(cleanLine[..<newline])
        }
        cleanLine = cleanLine
            .replacingOccurrences(of: "^[0-9]+\\.?\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^[•\\-\\*]\\s*", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^\"|\"$", with: "", options: .regularExpression)
            .replacingOccurrences(of: "^'|'$", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        if cleanLine.lowercased().hasPrefix(originalText.lowercased()),
           originalText.count < cleanLine.count {
            let startIndex = cleanLine.index(cleanLine.startIndex, offsetBy: originalText.count)
            cleanLine = String(cleanLine[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        guard !cleanLine.isEmpty else { return [] }
        return [cleanLine]
    }
    
    func cancelPredictionIfNeeded() {
        // Placeholder for future cancellation logic
    }
}
