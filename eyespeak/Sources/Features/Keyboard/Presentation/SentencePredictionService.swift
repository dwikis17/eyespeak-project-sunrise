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
    private var session: LanguageModelSession?
    #endif
    private var lastErrorTime: Date?
    private var errorCount = 0
    
    @Published var isModelAvailable = false
    @Published var sentencePredictions: [String] = []
    @Published var inlinePrediction: String = ""
    @Published var debugInfo: String = ""
    
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 1.0
    
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
            setupSession()
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
    
    private func setupSession() {
        guard let model = systemModel else { return }
        
        #if canImport(FoundationModels)
        do {
            let instructions = """
            You complete the user's sentence for assistive communication.
            Return only the remaining words needed to finish the sentence, include natural punctuation at the end, and avoid repeating the user's text.
            
            Examples:
            "I need" → " some help please."
            "Can you" → " help me find my mom?"
            "I want to" → " go back to my room."
            "How are" → " you feeling today?"
            
            Rules:
            - Provide one natural sentence ending (3–10 words total)
            - Include final punctuation (. ? or !)
            - Do not restate the user's original text
            - Keep tone conversational and supportive
            """
            
            session = try LanguageModelSession(instructions: instructions)
        } catch {
            print("Error setting up LanguageModelSession: \(error)")
            isModelAvailable = false
        }
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

        await ensureSessionAvailable()
        guard let session else {
            await MainActor.run {
                self.sentencePredictions = []
                self.inlinePrediction = ""
            }
            return
        }

        do {
            // Match earlier working API: respond(to:)
            let prompt = "Complete this text: \(trimmed)\nCompletion:"
            let response = try await session.respond(to: prompt)
            let parsed = parseCompletions(from: response.content, originalText: trimmed)
            let normalized = parsed
                .map { self.normalizeCompletion($0) }
                .filter { !$0.isEmpty }
            await MainActor.run {
                self.sentencePredictions = normalized
                self.inlinePrediction = normalized.first ?? ""
                self.debugInfo = parsed.isEmpty ? "AI: empty" : "AI: \(parsed.count) predictions"
            }
        } catch {
            recordError()
            await logGuardrailFeedback(for: trimmed, error: error)
            // Fall back to basic completions
            let fallback = generateFallbackCompletions(for: trimmed)
                .map { self.normalizeCompletion($0) }
                .filter { !$0.isEmpty }
            await MainActor.run {
                self.sentencePredictions = fallback
                self.inlinePrediction = fallback.first ?? ""
                self.debugInfo = "Fallback after error"
            }
        }
        #else
        await MainActor.run {
            self.sentencePredictions = []
            self.inlinePrediction = ""
        }
        #endif
    }
    
    func generateFallbackPredictions(for text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = trimmedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
        
        // Show basic completions even for a single word to keep feedback visible
        guard wordCount >= 1 else {
            await MainActor.run {
                self.sentencePredictions = []
            }
            return
        }
        
        let completions = generateFallbackCompletions(for: trimmedText)
            .map { normalizeCompletion($0) }
            .filter { !$0.isEmpty }
        await MainActor.run {
            self.sentencePredictions = completions
            self.inlinePrediction = completions.first ?? ""
        }
    }
    
    private func generateFallbackCompletions(for text: String) -> [String] {
        let lowercaseText = text.lowercased()
        var completions: [String] = []
        
        if lowercaseText.contains("i need to") {
            completions = ["go home", "rest now", "call someone"]
        } else if lowercaseText.contains("i want to") {
            completions = ["eat something", "go outside", "sleep"]
        } else if lowercaseText.contains("can you help") {
            completions = ["me please", "me now", "me with this"]
        } else if lowercaseText.contains("how are you") {
            completions = ["feeling", "doing", "today"]
        } else if lowercaseText.contains("what time") {
            completions = ["is it", "should we go", "do we leave"]
        } else if lowercaseText.contains("where are") {
            completions = ["you going", "we meeting", "you now"]
        } else if lowercaseText.contains("when will") {
            completions = ["you be back", "this end", "we leave"]
        } else if lowercaseText.contains("i feel") {
            completions = ["better today", "very tired", "much better"]
        } else if lowercaseText.contains("thank you") {
            completions = ["so much", "very much", "for helping"]
        } else if lowercaseText.contains("good morning") {
            completions = ["everyone", "doctor", "to you"]
        } else if lowercaseText.contains("see you") {
            completions = ["later", "tomorrow", "soon"]
        } else if lowercaseText.contains("have a") {
            completions = ["good day", "nice time", "safe trip"]
        } else if lowercaseText.contains("please help") {
            completions = ["me", "me now", "me understand"]
        } else if lowercaseText.contains("i would like") {
            completions = ["some water", "to rest", "to go home"]
        } else if lowercaseText.contains("could you") {
            completions = ["help me", "come here", "call someone"]
        } else if lowercaseText.contains("i am feeling") {
            completions = ["better today", "very tired", "much better"]
        } else if lowercaseText.contains("let me know") {
            completions = ["when ready", "if possible", "the time"]
        } else if lowercaseText.contains("the doctor") {
            completions = ["said to rest", "will see me", "gave me medicine"]
        } else if lowercaseText.contains("my medication") {
            completions = ["helps me", "is working", "needs food"]
        } else if lowercaseText.contains("i am going") {
            completions = ["home now", "to rest", "to the doctor"]
        } else if lowercaseText.contains("it is time") {
            completions = ["to go", "to eat", "for medicine"]
        } else if lowercaseText.hasSuffix("i need") {
            completions = ["help", "water", "to rest"]
        } else if lowercaseText.hasSuffix("i want") {
            completions = ["some food", "to go home", "to rest"]
        } else if lowercaseText.hasSuffix("i am") || lowercaseText.hasSuffix("i'm") {
            completions = ["tired", "ready", "feeling better"]
        } else if lowercaseText.hasSuffix("can you") {
            completions = ["help me", "come here", "call"]
        } else if lowercaseText.hasSuffix("how are") {
            completions = ["you", "you feeling", "things"]
        } else if lowercaseText.hasSuffix("thank") {
            completions = ["you", "you so much", "you very much"]
        } else if lowercaseText.hasSuffix("see you") {
            completions = ["later", "soon", "tomorrow"]
        } else if lowercaseText.hasSuffix("good") {
            completions = ["morning", "afternoon", "evening"]
        } else if lowercaseText.hasSuffix("have a") {
            completions = ["good day", "nice time", "safe trip"]
        } else if lowercaseText.hasSuffix("what") {
            completions = ["time is it", "are you doing", "happened"]
        } else if lowercaseText.hasSuffix("where") {
            completions = ["are you", "is it", "should I go"]
        } else if lowercaseText.hasSuffix("when") {
            completions = ["will you return", "should we leave", "is dinner"]
        } else if lowercaseText.hasSuffix("please") {
            completions = ["help me", "come here", "wait"]
        } else if lowercaseText.contains("feel") {
            completions = ["better", "tired", "good"]
        } else if lowercaseText.contains("time") {
            completions = ["to go", "for food", "to rest"]
        } else if lowercaseText.contains("help") {
            completions = ["me please", "is needed", "would be nice"]
        } else if lowercaseText.contains("water") {
            completions = ["please", "and food", "is needed"]
        } else if lowercaseText.contains("food") {
            completions = ["please", "and water", "would be good"]
        } else {
            if lowercaseText.contains("i") {
                completions = ["need help", "am tired", "feel better"]
            } else if lowercaseText.contains("you") {
                completions = ["can help", "are kind", "should know"]
            } else if lowercaseText.contains("we") {
                completions = ["should go", "can do this", "are ready"]
            } else {
                completions = ["please", "thank you", "yes"]
            }
        }
        
        return Array(completions.prefix(3))
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
            do {
                guard let _ = session else { return }
                print("Guardrail may have been triggered incorrectly for text: '\(text)'")
                print("Consider filing feedback at https://feedbackassistant.apple.com")
            } catch {
                print("Failed to log feedback: \(error)")
            }
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
    
    private func ensureSessionAvailable() async {
        #if canImport(FoundationModels)
        guard session == nil || !isModelAvailable else { return }
        checkModelAvailability()
        #endif
    }
    
    private func parseCompletions(from content: String, originalText: String) -> [String] {
        let rejectionPatterns = [
            "i can't assist",
            "i cannot help",
            "i'm sorry",
            "i can't help",
            "unable to assist",
            "cannot provide"
        ]
        let lowercaseContent = content.lowercased()
        for pattern in rejectionPatterns {
            if lowercaseContent.contains(pattern) {
                return []
            }
        }
        let separators = CharacterSet(charactersIn: "\n•-*123456789")
        let lines = content.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var completions: [String] = []
        for line in lines.prefix(5) {
            var cleanLine = line
                .replacingOccurrences(of: "^[0-9]+\\.?\\s*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^[•\\-\\*]\\s*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^\"|\"$", with: "")
                .replacingOccurrences(of: "^'|'$", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            cleanLine = cleanLine.replacingOccurrences(of: "^(completion|answer|response):\\s*", with: "", options: [.regularExpression, .caseInsensitive])
            if cleanLine.lowercased().hasPrefix(originalText.lowercased()) {
                if originalText.count < cleanLine.count {
                    let startIndex = cleanLine.index(cleanLine.startIndex, offsetBy: originalText.count)
                    cleanLine = String(cleanLine[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            if !cleanLine.isEmpty &&
               cleanLine.count >= 2 &&
               cleanLine.count <= 40 &&
               !cleanLine.lowercased().contains("i can't") &&
               !cleanLine.lowercased().contains("sorry") &&
               !cleanLine.lowercased().contains("cannot") &&
               !cleanLine.starts(with: originalText) {
                completions.append(cleanLine)
            }
        }
        return Array(completions.prefix(3))
    }
    
    func cancelPredictionIfNeeded() {
        // Placeholder for future cancellation logic
    }
}
