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
            You are an assistive sentence completion partner running entirely on-device.
            Deliver one natural continuation that preserves the user's tense, voice, and tone without repeating their input.
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
            let prompt = """
            Complete this text naturally and contextually. Return only the completion without repeating the input.
            Maintain the same tone and style.
            
            \(trimmed)
            """
            let response = try await session.respond(to: prompt)
            let parsed = parseCompletions(from: response.content, originalText: trimmed)
            let normalized = parsed
                .map { self.normalizeCompletion($0) }
                .filter { !$0.isEmpty }
            let primary = normalized.first ?? ""
            let single = primary.isEmpty ? [] : [primary]
            await MainActor.run {
                self.sentencePredictions = single
                self.inlinePrediction = primary
                self.debugInfo = primary.isEmpty ? "AI: empty" : "AI: completion"
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
