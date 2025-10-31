//
//  KeyboardView.swift
//  eyespeak
//
//  Created by Dwiki on 16/10/25.
//

import SwiftUI
import UIKit
internal import Combine

// Conditional import for FoundationModels
#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Sentence Prediction Service

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
    @Published var inlinePrediction: String = "" // New inline prediction property
    @Published var debugInfo: String = "" // Debug information
    
    private var lastRequestTime: Date?
    private let minRequestInterval: TimeInterval = 1.0 // 1 second between requests
    
    init() {
        checkModelAvailability()
    }
    
    private func checkModelAvailability() {
        // Safely check if FoundationModels is available
        guard #available(iOS 18.1, *) else {
            print("FoundationModels requires iOS 18.1 or later")
            isModelAvailable = false
            return
        }
        
        #if canImport(FoundationModels)
        systemModel = SystemLanguageModel.default
        
        guard let model = systemModel else {
            print("SystemLanguageModel not available")
            isModelAvailable = false
            return
        }
        
        switch model.availability {
        case .available:
            print("✅ Apple Intelligence model available")
            isModelAvailable = true
            setupSession()
        case .unavailable(.deviceNotEligible):
            print("❌ Device not eligible for Apple Intelligence")
            isModelAvailable = false
        case .unavailable(.appleIntelligenceNotEnabled):
            print("❌ Apple Intelligence not enabled - check Settings > Apple Intelligence & Siri")
            isModelAvailable = false
        case .unavailable(.modelNotReady):
            print("⏳ Model is downloading or not ready - try again later")
            isModelAvailable = false
            // Schedule a retry in a few seconds
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000)
                checkModelAvailability()
            }
        case .unavailable(let other):
            print("❌ Model unavailable: \(other)")
            isModelAvailable = false
        }
        #else
        print("FoundationModels framework not available")
        isModelAvailable = false
        #endif
    }
    
    private func setupSession() {
        guard let model = systemModel else { return }
        
        #if canImport(FoundationModels)
        do {
            let instructions = """
            Complete text naturally for daily communication. 
            
            Examples:
            "I need" → "some help"
            "Can you" → "help me"
            "I want" → "to go home"
            "How are" → "you doing"
            
            Rules:
            - One completion only
            - Keep it simple and natural
            - 2-6 words max
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
        // Early return if model isn't available
        guard isModelAvailable,
              let currentSession = session else {
            await MainActor.run {
                self.sentencePredictions = []
            }
            return
        }
        
        // Check if session is busy
        guard !currentSession.isResponding else {
            print("Session is already responding")
            return
        }
        
        guard !text.isEmpty else {
            await MainActor.run {
                self.sentencePredictions = []
            }
            return
        }
        
        // Only generate predictions if we have meaningful text with enough context
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let wordCount = trimmedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }.count
            
        guard wordCount >= 2 else { // Lowered threshold
            await MainActor.run {
                self.sentencePredictions = []
                self.debugInfo = "Need at least 2 words (current: \(wordCount))"
            }
            return
        }
        
        // Sanitize input to avoid triggering safety guardrails
        let sanitizedText = sanitizeInput(trimmedText)
        guard !sanitizedText.isEmpty else {
            await MainActor.run {
                self.sentencePredictions = []
            }
            return
        }
        
        // Check for rate limiting
        if shouldRateLimit() {
            print("Rate limiting active due to recent errors")
            return
        }
        
        // Throttle requests to avoid accumulator errors
        if let lastRequestTime = lastRequestTime {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequestTime)
            if timeSinceLastRequest < minRequestInterval {
                try? await Task.sleep(nanoseconds: UInt64((minRequestInterval - timeSinceLastRequest) * 1_000_000_000))
            }
        }
        lastRequestTime = Date()
        
        // Ensure we have a valid session
        await ensureSessionAvailable()
        
        do {
            // Use a very simple prompt to avoid triggering guardrails
            let prompt = "Complete this text: \(sanitizedText)"
            
            print("🤖 Sending to Apple Intelligence: '\(sanitizedText)'")
            let response = try await currentSession.respond(to: prompt)
            print("🤖 AI Response: '\(response.content)'")
            
            let completions = parseCompletions(from: response.content, originalText: sanitizedText)
            
            // If we got completions from the AI, use them
            if !completions.isEmpty {
                print("✅ Using AI completions: \(completions)")
                // Reset error count on success
                resetErrorCount()
                
                await MainActor.run {
                    self.sentencePredictions = completions
                    self.inlinePrediction = completions.first ?? ""
                    self.debugInfo = "AI: \(completions.count) predictions"
                }
            } else {
                print("⚠️ AI returned empty, using fallback")
                // Use fallback for both regular and inline predictions
                let fallbackCompletions = generateFallbackCompletions(for: sanitizedText)
                await MainActor.run {
                    self.sentencePredictions = fallbackCompletions
                    self.inlinePrediction = fallbackCompletions.first ?? ""
                    self.debugInfo = "Fallback: AI empty response"
                }
            }
        } catch {
            recordError()
            
            // Handle FoundationModels specific errors
            if let generationError = error as? LanguageModelSession.GenerationError {
                switch generationError {
                case .guardrailViolation(let context):
                    print("❌ Guardrail violation: \(context.debugDescription)")
                    // Try fallback predictions instead
                    let fallbackCompletions = generateFallbackCompletions(for: sanitizedText)
                    await MainActor.run {
                        self.sentencePredictions = fallbackCompletions
                        self.inlinePrediction = fallbackCompletions.first ?? ""
                        self.debugInfo = "Fallback: Guardrail violation"
                    }
                    return
                case .exceededContextWindowSize:
                    print("Context window size exceeded")
                @unknown default:
                    print("FoundationModels error: \(generationError)")
                    // Check if the model became unavailable
                    if generationError.localizedDescription.contains("unavailable") {
                        await MainActor.run {
                            self.isModelAvailable = false
                            self.session = nil
                        }
                    }
                }
            } else {
                print("Error generating sentence predictions: \(error)")
                // Try fallback predictions for any other error
                let fallbackCompletions = generateFallbackCompletions(for: sanitizedText)
                await MainActor.run {
                    self.sentencePredictions = fallbackCompletions
                    self.inlinePrediction = fallbackCompletions.first ?? ""
                }
                return
            }
            
            await MainActor.run {
                self.sentencePredictions = []
                self.inlinePrediction = ""
            }
        }
        #else
        // FoundationModels not available
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
            
        guard wordCount >= 2 else { // Lower threshold for fallback
            await MainActor.run {
                self.sentencePredictions = []
            }
            return
        }
        
        let completions = generateFallbackCompletions(for: trimmedText)
        await MainActor.run {
            self.sentencePredictions = completions
            self.inlinePrediction = completions.first ?? ""
        }
    }
    
    private func generateFallbackCompletions(for text: String) -> [String] {
        let lowercaseText = text.lowercased()
        var completions: [String] = []
        
        // Practical, shorter completions for daily communication
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
        }
        // Single word endings with shorter, practical completions
        else if lowercaseText.hasSuffix("i need") {
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
            // Generic shorter fallbacks
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
    
    private func sanitizeInput(_ text: String) -> String {
        // Remove potentially problematic characters or patterns
        var sanitized = text
        
        // Remove excessive repetition that might trigger guardrails
        sanitized = sanitized.replacingOccurrences(of: "(.{1,3})\\1{3,}", with: "$1$1", options: .regularExpression)
        
        // Limit length to prevent context window issues
        if sanitized.count > 200 {
            sanitized = String(sanitized.prefix(200))
        }
        
        // Remove potentially sensitive patterns
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
        // Only log feedback for seemingly inappropriate guardrail triggers
        // This helps Apple improve the model
        if let generationError = error as? LanguageModelSession.GenerationError,
           case .guardrailViolation = generationError {
            do {
                // Create a basic transcript entry for feedback
                guard let session = session else { return }
                
                // Note: The feedback API may not be available in all versions
                // This is a placeholder for when the API becomes available
                print("Guardrail may have been triggered incorrectly for text: '\(text)'")
                print("Consider filing feedback at https://feedbackassistant.apple.com")
                
                // If the logFeedbackAttachment API becomes available, uncomment:
                // let feedbackAttachment = try await session.logFeedbackAttachment(
                //     sentiment: .negative,
                //     issues: [.blocked],
                //     desiredOutput: "Simple text completion for assistive keyboard"
                // )
                
            } catch {
                print("Failed to log feedback: \(error)")
            }
        }
        #endif
    }
    
    private func shouldRateLimit() -> Bool {
        guard let lastErrorTime = lastErrorTime else { return false }
        
        // Rate limit for 5 seconds after errors
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
        
        // Try to recreate the session
        checkModelAvailability()
        #endif
    }
    
    private func parseCompletions(from content: String, originalText: String) -> [String] {
        // Check for common rejection patterns first
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
                return [] // Return empty array to trigger fallback
            }
        }
        
        // Split by common delimiters
        let separators = CharacterSet(charactersIn: "\n•-*123456789")
        let lines = content.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        var completions: [String] = []
        
        for line in lines.prefix(5) { // Check more lines for better results
            // Clean up the line - remove quotes, bullet points, numbers
            var cleanLine = line
                .replacingOccurrences(of: "^[0-9]+\\.?\\s*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^[•\\-\\*]\\s*", with: "", options: .regularExpression)
                .replacingOccurrences(of: "^\"|\"$", with: "")
                .replacingOccurrences(of: "^'|'$", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Remove prefixes like "Completion:" or "Answer:"
            cleanLine = cleanLine.replacingOccurrences(of: "^(completion|answer|response):\\s*", with: "", options: [.regularExpression, .caseInsensitive])
            
            // Ensure it doesn't repeat the original text
            if cleanLine.lowercased().hasPrefix(originalText.lowercased()) {
                if originalText.count < cleanLine.count {
                    let startIndex = cleanLine.index(cleanLine.startIndex, offsetBy: originalText.count)
                    cleanLine = String(cleanLine[startIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            
            // Quality filter for completions
            if !cleanLine.isEmpty &&
               cleanLine.count >= 2 &&
               cleanLine.count <= 40 && // Shorter max length
               !cleanLine.lowercased().contains("i can't") &&
               !cleanLine.lowercased().contains("sorry") &&
               !cleanLine.lowercased().contains("cannot") &&
               !cleanLine.starts(with: originalText) { // Don't repeat input
                completions.append(cleanLine)
            }
        }
        
        return Array(completions.prefix(3))
    }
}

// MARK: - Inline TextField with Prediction

struct InlineTextFieldWithPrediction: View {
    @Binding var text: String
    let prediction: String
    let onAcceptPrediction: () -> Void
    @State private var textFieldHeight: CGFloat = 60
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            
            // Main text field
            TextField("Start typing here...", text: $text, axis: .vertical)
                .font(.system(size: 24))
                .padding(20)
                .lineLimit(10...20)
                .background(Color.clear)
            
            // Prediction overlay - only show when there's both text and prediction
            if !prediction.isEmpty && !text.isEmpty {
                HStack(alignment: .top, spacing: 0) {
                    // Invisible text to align prediction properly
                    Text(text)
                        .font(.system(size: 24))
                        .opacity(0)
                    
                    // Actual prediction text
                    Text(prediction)
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .allowsHitTesting(false)
                    
                    Spacer(minLength: 0)
                }
                .padding(20)
            }
        }
        .onTapGesture(count: 2) {
            // Double tap to accept prediction
            if !prediction.isEmpty {
                onAcceptPrediction()
            }
        }
    }
}

// MARK: - Keyboard Components

struct KeyboardRowView: View {
    let keys: [String]
    let onKeyTap: (String) -> Void
    let highlightedIndex: Int?
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(Array(keys.enumerated()), id: \.element) { index, key in
                KeyButton(
                    key: key,
                    action: { onKeyTap(key) },
                    isHighlighted: highlightedIndex == index
                )
            }
        }
        .frame(height: 70)
    }
}

struct KeyButton: View {
    let key: String
    let action: () -> Void
    let isHighlighted: Bool
    
    var body: some View {
        Button(action: action) {
            Text(key)
                .font(.system(size: 24, weight: .medium))
                .frame(minWidth: 60, minHeight: 60)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(isHighlighted ? Color.accentColor.opacity(0.25) : Color(.systemGray4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isHighlighted ? Color.accentColor : Color.clear, lineWidth: 3)
                )
                .cornerRadius(8)
        }
    }
}

struct SentencePredictionRowView: View {
    let predictions: [String]
    let onTap: (String) -> Void
    let highlightedIndex: Int?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Array(predictions.enumerated()), id: \.element) { index, prediction in
                    Button(action: { onTap(prediction) }) {
                        VStack(spacing: 4) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                Text(prediction)
                                    .font(.system(size: 16, weight: .medium))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(highlightedIndex == index ? Color.accentColor.opacity(0.2) : Color(.systemGray5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(highlightedIndex == index ? Color.accentColor : Color.clear, lineWidth: 2)
                                    )
                            )
                            
                            Circle()
                                .fill(highlightedIndex == index ? Color.accentColor : Color.clear)
                                .frame(width: 6, height: 6)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 70)
    }
}

struct SuggestionRowView: View {
    let suggestions: [String]
    let onTap: (String) -> Void
    let highlightedIndex: Int?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(suggestions.enumerated()), id: \.element) { index, suggestion in
                    Button(action: { onTap(suggestion) }) {
                        VStack(spacing: 6) {
                            Text(suggestion)
                                .font(.system(size: 18, weight: .medium))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(highlightedIndex == index ? Color.accentColor : Color.clear, lineWidth: 3)
                                )
                                .cornerRadius(20)
                            Circle()
                                .fill(highlightedIndex == index ? Color.accentColor : Color.clear)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 70)
    }
}

struct CapsLockKeyView: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            Image(systemName: isOn ? "capslock.fill" : "capslock")
                .font(.system(size: 24))
                .frame(width: 80, height: 60)
                .background(isOn ? Color.accentColor.opacity(0.2) : Color(.systemGray4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isOn ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .cornerRadius(8)
        }
    }
}

struct ShiftKeyView: View {
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            Image(systemName: isOn ? "shift.fill" : "shift")
                .font(.system(size: 24))
                .frame(width: 80, height: 60)
                .background(isOn ? Color.accentColor.opacity(0.2) : Color(.systemGray4))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isOn ? Color.accentColor : Color.clear, lineWidth: 2)
                )
                .cornerRadius(8)
        }
    }
}

struct DeleteKeyView: View {
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onDelete) {
            Image(systemName: "delete.left")
                .font(.system(size: 24))
                .frame(width: 80, height: 60)
                .background(Color(.systemGray4))
                .cornerRadius(8)
        }
    }
}

struct NumbersKeyView: View {
    var body: some View {
        Button(action: {
            // Numbers toggle
        }) {
            Text("123")
                .font(.system(size: 20, weight: .medium))
                .frame(width: 100, height: 60)
                .background(Color(.systemGray4))
                .cornerRadius(8)
        }
    }
}

struct SpaceKeyView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text("space")
                .font(.system(size: 20, weight: .medium))
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(Color(.systemGray4))
                .cornerRadius(8)
        }
    }
}

struct ReturnKeyView: View {
    var body: some View {
        Button(action: {
            // Return action
        }) {
            Text("return")
                .font(.system(size: 20, weight: .medium))
                .frame(width: 120, height: 60)
                .background(Color(.systemGray4))
                .cornerRadius(8)
        }
    }
}

// MARK: - Main Keyboard View

struct KeyboardView: View {
    @State private var text: String = ""
    @State private var suggestions: [String] = []
    @State private var shortcuts: [String: String] = [:]
    @State private var isShiftOn: Bool = false
    @State private var isCapsLockOn: Bool = false
    
    @StateObject private var predictionService = SentencePredictionService()
    
    @State private var predictionTask: Task<Void, Never>?
    @State private var isAcceptingPrediction = false
    
    private let textChecker = UITextChecker()
    
    private let topRowKeys = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
    private let middleRowKeys = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
    private let bottomRowKeys = ["Z", "X", "C", "V", "B", "N", "M"]
    
    private var isUppercase: Bool { isCapsLockOn || isShiftOn }
    private var displayedTopRowKeys: [String] {
        isUppercase ? topRowKeys : topRowKeys.map { $0.lowercased() }
    }
    private var displayedMiddleRowKeys: [String] {
        isUppercase ? middleRowKeys : middleRowKeys.map { $0.lowercased() }
    }
    private var displayedBottomRowKeys: [String] {
        isUppercase ? bottomRowKeys : bottomRowKeys.map { $0.lowercased() }
    }
    
    private enum ScanGroup: CaseIterable { case sentencePredictions, suggestions, top, middle, bottom, function }
    @State private var scanningEnabled = true
    @State private var scanInterval: Double = 1.2
    @State private var scanGroup: ScanGroup = .sentencePredictions
    @State private var scanIndex: Int = 0
    @State private var timer = Timer.publish(every: 1.2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                textInputView
                    .frame(height: geometry.size.height * 0.2)
                
                sentencePredictionsView
                    .frame(height: 80)
                
                suggestionsView
                    .frame(height: 70)
                
                keyboardLayoutView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding(.horizontal, 20)
            .background(Color(.systemGroupedBackground))
        }
        .onAppear {
            loadShortcuts()
        }
        .onReceive(timer) { _ in
            if scanningEnabled { advanceScan() }
        }
    }
    
    private var textInputView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Type your message:")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !predictionService.inlinePrediction.isEmpty {
                    Button("Accept") {
                        acceptInlinePrediction()
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accentColor)
                }
            }
            
            ScrollView {
                InlineTextFieldWithPrediction(
                    text: $text,
                    prediction: predictionService.inlinePrediction,
                    onAcceptPrediction: acceptInlinePrediction
                )
            }
        }
        .padding(.top, 20)
        .onChange(of: text) { newValue in
            guard !isAcceptingPrediction else { return }
            
            predictionTask?.cancel()
            
            if !predictionService.inlinePrediction.isEmpty {
                Task {
                    await MainActor.run {
                        predictionService.inlinePrediction = ""
                    }
                }
            }
            
            checkForShortcuts(in: newValue)
            updateSuggestions(for: newValue)
            
            let wordCount = countWords(in: newValue)
            
            if predictionService.isModelAvailable && wordCount >= 2 {
                predictionTask = Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    
                    guard !Task.isCancelled else { return }
                    guard !isAcceptingPrediction else { return }
                    
                    await predictionService.generateSentencePredictions(for: newValue)
                }
            } else if !predictionService.isModelAvailable && wordCount >= 2 {
                predictionTask = Task {
                    try? await Task.sleep(nanoseconds: 1_500_000_000)
                    
                    guard !Task.isCancelled else { return }
                    guard !isAcceptingPrediction else { return }
                    
                    await predictionService.generateFallbackPredictions(for: newValue)
                }
            } else {
                Task {
                    await MainActor.run {
                        predictionService.sentencePredictions = []
                        predictionService.inlinePrediction = ""
                    }
                }
            }
        }
    }
    
    private var sentencePredictionsView: some View {
        VStack(spacing: 0) {
            if !predictionService.sentencePredictions.isEmpty {
                HStack {
                    Image(systemName: predictionService.isModelAvailable ? "wand.and.stars" : "lightbulb")
                        .foregroundColor(predictionService.isModelAvailable ? .accentColor : .orange)
                    Text(predictionService.isModelAvailable ? "Smart Completions:" : "Text Completions:")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        if !predictionService.inlinePrediction.isEmpty {
                            Text("• Inline suggestion available")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        if !predictionService.debugInfo.isEmpty {
                            Text(predictionService.debugInfo)
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding(.bottom, 8)
                
                SentencePredictionRowView(
                    predictions: predictionService.sentencePredictions,
                    onTap: applySentencePrediction,
                    highlightedIndex: scanGroup == .sentencePredictions ? scanIndex : nil
                )
            } else {
                let wordCount = countWords(in: text)
                let minWords = 2
                
                VStack {
                    HStack {
                        Image(systemName: predictionService.isModelAvailable ? "wand.and.stars" : "lightbulb")
                            .foregroundColor(.secondary)
                        Text(predictionService.isModelAvailable ? "Smart Completions:" : "Text Completions:")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    
                    if !predictionService.inlinePrediction.isEmpty {
                        Text("Double-tap the text field or tap 'Accept' to use the inline suggestion")
                            .font(.system(size: 12))
                            .foregroundColor(.accentColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if wordCount > 0 && wordCount < minWords {
                        Text("Type \(minWords - wordCount) more word\(minWords - wordCount == 1 ? "" : "s") for suggestions")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else if !predictionService.isModelAvailable && wordCount == 0 {
                        Text("Apple Intelligence unavailable - using basic predictions")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.bottom, 8)
                Rectangle().fill(Color.clear).frame(height: 70)
            }
        }
    }
    
    private var suggestionsView: some View {
        VStack(spacing: 0) {
            if !suggestions.isEmpty {
                Text("Word Suggestions:")
                    .font(.system(size: 16, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                SuggestionRowView(
                    suggestions: suggestions,
                    onTap: applySuggestion,
                    highlightedIndex: scanGroup == .suggestions ? scanIndex : nil
                )
            } else {
                Rectangle().fill(Color.clear).frame(height: 70)
            }
        }
    }

    private var keyboardLayoutView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            KeyboardRowView(
                keys: displayedTopRowKeys,
                onKeyTap: appendText,
                highlightedIndex: scanGroup == .top ? scanIndex : nil
            )
            
            HStack(spacing: 12) {
                Spacer().frame(width: 30)
                KeyboardRowView(
                    keys: displayedMiddleRowKeys,
                    onKeyTap: appendText,
                    highlightedIndex: scanGroup == .middle ? scanIndex : nil
                )
                Spacer().frame(width: 30)
            }
            
            HStack(spacing: 12) {
                CapsLockKeyView(isOn: $isCapsLockOn)
                ShiftKeyView(isOn: $isShiftOn)
                KeyboardRowView(
                    keys: displayedBottomRowKeys,
                    onKeyTap: appendText,
                    highlightedIndex: scanGroup == .bottom ? scanIndex : nil
                )
                DeleteKeyView(onDelete: {
                    if !text.isEmpty {
                        text.removeLast()
                    }
                })
            }
            
            HStack(spacing: 12) {
                NumbersKeyView()
                SpaceKeyView(onTap: { appendText(" ") })
                ReturnKeyView()
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.bottom, 20)
    }
    
    private func acceptInlinePrediction() {
        guard !predictionService.inlinePrediction.isEmpty else { return }
        
        let predictionToAdd = predictionService.inlinePrediction
        isAcceptingPrediction = true
        
        Task {
            await MainActor.run {
                predictionService.inlinePrediction = ""
                predictionService.sentencePredictions = []
            }
        }
        
        text += predictionToAdd
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAcceptingPrediction = false
        }
    }
    
    private func countWords(in text: String) -> Int {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return 0 }
        
        let words = trimmedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return words.count
    }
    
    private func appendText(_ string: String) {
        text += string
        if isShiftOn && !isCapsLockOn {
            isShiftOn = false
        }
    }
    
    private func applySentencePrediction(_ prediction: String) {
        isAcceptingPrediction = true
        
        Task {
            await MainActor.run {
                predictionService.sentencePredictions = []
                predictionService.inlinePrediction = ""
            }
        }
        
        if text.hasSuffix(" ") {
            text += prediction
        } else {
            text += " " + prediction
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            isAcceptingPrediction = false
        }
    }
    
    private func applySuggestion(_ suggestion: String) {
        guard let lastWordRange = findLastWordRange() else { return }
        
        let nsRange = NSRange(lastWordRange, in: text)
        let nsString = text as NSString
        text = nsString.replacingCharacters(in: nsRange, with: suggestion)
        
        suggestions = []
    }
    
    private func findLastWordRange() -> Range<String.Index>? {
        if text.isEmpty {
            return nil
        }
        
        let lastWordStartIndex = text.lastIndex(where: { $0 == " " || $0 == "\n" })
        
        if lastWordStartIndex == nil {
            return text.startIndex..<text.endIndex
        }
        
        let startIndex = text.index(after: lastWordStartIndex!)
        
        return startIndex..<text.endIndex
    }
    
    private func updateSuggestions(for text: String) {
        guard !text.isEmpty else {
            suggestions = []
            return
        }
        
        guard let lastWordRange = findLastWordRange() else {
            suggestions = []
            return
        }
        
        let lastWord = String(text[lastWordRange])
        
        guard lastWord.count >= 2 else {
            suggestions = []
            return
        }
        
        let nsRange = NSRange(location: 0, length: lastWord.utf16.count)
        let completions = textChecker.completions(forPartialWordRange: nsRange,
                                                 in: lastWord,
                                                 language: "en_US") ?? []
        
        suggestions = Array(completions.prefix(5))
    }
    
    private func loadShortcuts() {
        shortcuts = [
            "omw": "On my way!",
            "brb": "Be right back",
            "ttyl": "Talk to you later",
            "ty": "Thank you",
            "np": "No problem"
        ]
    }
    
    private func checkForShortcuts(in newText: String) {
        guard let lastWordRange = findLastWordRange() else { return }
        let lastWord = String(text[lastWordRange])
        
        if let replacement = shortcuts[lastWord], lastWord != replacement {
            if text.hasSuffix(" \(lastWord)") || text == lastWord {
                let nsRange = NSRange(lastWordRange, in: text)
                let nsString = text as NSString
                text = nsString.replacingCharacters(in: nsRange, with: replacement)
            }
        }
    }

    private func advanceScan() {
        let count = groupCount(for: scanGroup)
        if count == 0 {
            moveToNextAvailableGroup()
            return
        }
        let next = scanIndex + 1
        if next >= count {
            scanIndex = 0
            scanGroup = nextGroup(after: scanGroup)
            if groupCount(for: scanGroup) == 0 {
                moveToNextAvailableGroup()
            }
        } else {
            scanIndex = next
        }
    }

    private func groupCount(for group: ScanGroup) -> Int {
        switch group {
        case .sentencePredictions: return predictionService.sentencePredictions.count
        case .suggestions: return suggestions.count
        case .top: return topRowKeys.count
        case .middle: return middleRowKeys.count
        case .bottom: return bottomRowKeys.count
        case .function: return 3
        }
    }

    private func nextGroup(after group: ScanGroup) -> ScanGroup {
        switch group {
        case .sentencePredictions: return .suggestions
        case .suggestions: return .top
        case .top: return .middle
        case .middle: return .bottom
        case .bottom: return .function
        case .function: return .sentencePredictions
        }
    }

    private func moveToNextAvailableGroup() {
        var candidate = nextGroup(after: scanGroup)
        var tries = 0
        while groupCount(for: candidate) == 0 && tries < ScanGroup.allCases.count {
            candidate = nextGroup(after: candidate)
            tries += 1
        }
        scanGroup = candidate
        scanIndex = 0
    }
}

#Preview {
    KeyboardView()
}
