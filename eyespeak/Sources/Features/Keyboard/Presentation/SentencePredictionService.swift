//
//  SentencePredictionService.swift
//  eyespeak
//
//  Extracted from KeyboardView.swift to simplify debugging and separation
//

import Foundation
import Combine

@MainActor
class SentencePredictionService: ObservableObject {
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

    private let openAIClient: OpenAIClient
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

    init(openAIClient: OpenAIClient = OpenAIClient()) {
        self.openAIClient = openAIClient
        checkModelAvailability()
    }

    private func checkModelAvailability() {
        let available = openAIClient.isConfigured
        isModelAvailable = available
        debugInfo = available ? "OpenAI: ready" : "Set OPENAI_API_KEY"
        print("🔍 SentencePredictionService availability: \(available ? "ready" : "missing key")")
    }

    func generateSentencePredictions(for text: String) async {
        let trimmedInput = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard isModelAvailable else {
            print("⚠️ SentencePredictionService: model unavailable (missing key)")
            await MainActor.run {
                self.sentencePredictions = []
                self.inlinePrediction = ""
            }
            return
        }

        guard !trimmedInput.isEmpty else {
            print("ℹ️ SentencePredictionService: skipped empty input")
            await MainActor.run {
                self.sentencePredictions = []
                self.inlinePrediction = ""
            }
            return
        }

        guard !shouldRateLimit() else {
            print("⏳ SentencePredictionService: rate limited after errors")
            await MainActor.run {
                self.sentencePredictions = []
                self.inlinePrediction = ""
            }
            return
        }

        let trimmed = sanitizeInput(text)
        let now = Date()
        if let last = lastRequestTime, now.timeIntervalSince(last) < minRequestInterval {
            return
        }
        lastRequestTime = now

        do {
            print("🚀 SentencePredictionService: requesting completion for \(trimmed.count) chars")
            let response = try await openAIClient.complete(
                systemPrompt: Self.sessionInstructions,
                userPrompt: prompt(for: trimmed)
            )
            let parsed = parseCompletions(from: response, originalText: trimmed)
                .map { self.normalizeCompletion($0) }
                .filter { !$0.isEmpty }
            let prediction = parsed.first ?? ""
            print("✅ SentencePredictionService: completion parsed chars=\(prediction.count)")

            let debugLabel: String
            if prediction.isEmpty {
                debugLabel = "OpenAI: empty"
            } else if isAssistantTone(prediction) {
                logAssistantToneDetection(input: trimmed, prediction: prediction)
                debugLabel = "OpenAI: assistant"
            } else {
                debugLabel = "OpenAI: completion"
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
            logAPIError(for: trimmed, error: error)
            await MainActor.run {
                self.sentencePredictions = []
                self.inlinePrediction = ""
                self.debugInfo = shortErrorDescription(for: error)
            }
        }
    }

    private func shortErrorDescription(for error: Error) -> String {
        if let clientError = error as? OpenAIClient.ClientError,
           let description = clientError.errorDescription {
            return description
        }
        return "OpenAI error"
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

    private func logAPIError(for text: String, error: Error) {
        let snippet = text.prefix(80)
        print("❌ OpenAI completion failed for input '\(snippet)': \(error)")
    }

    func cancelPredictionIfNeeded() {
        // Placeholder for future cancellation logic
    }
}
