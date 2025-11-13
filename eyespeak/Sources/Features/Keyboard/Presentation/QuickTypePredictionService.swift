import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

actor QuickTypePredictionService {
    private struct CacheEntry {
        let predictions: [String]
        let timestamp: Date
    }
    
    private var cache: [String: CacheEntry] = [:]
    private let cacheTTL: TimeInterval = 2
    private let maxEntries = 64
    
    #if canImport(FoundationModels)
    private var session: LanguageModelSession?
    #endif
    
    init() {
        #if canImport(FoundationModels)
        Task {
            await setupSession()
        }
        #endif
    }
    
    func predictions(for text: String) async -> [String] {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return [] }
        
        #if canImport(FoundationModels)
        await ensureSessionAvailable()
        guard let session else { return [] }
        
        let key = cacheKey(for: normalized)
        if let cached = cachedPredictions(for: key) {
            return cached
        }
        
        do {
            let prompt = """
            Context: \(normalized)
            Predict exactly 3 short, natural next words.
            Return format: word1, word2, word3
            """
            let response = try await session.respond(to: prompt)
            let parsed = parseList(response.content)
            cache(predictions: parsed, for: key)
            return parsed
        } catch {
            return []
        }
        #else
        return []
        #endif
    }
    
    #if canImport(FoundationModels)
    private func setupSession() async {
        guard session == nil else { return }
        do {
            let instructions = """
            You predict the next word a person might type on an assistive keyboard.
            When you respond, output three lowercase options separated by commas (word1, word2, word3) with no explanation.
            Favor concise, high-confidence words that fit the supplied context.
            """
            session = try LanguageModelSession(instructions: instructions)
        } catch {
            session = nil
        }
    }
    
    private func ensureSessionAvailable() async {
        if session == nil {
            await setupSession()
        }
    }
    #endif
    
    private func parseList(_ text: String) -> [String] {
        let primarySeparators = CharacterSet(charactersIn: ",\n")
        let primaryTokens = text.components(separatedBy: primarySeparators)
        var cleaned = sanitizeTokens(primaryTokens)
        
        if cleaned.count < 3 {
            // Fall back to whitespace-delimited scan if the model ignored instructions.
            let secondaryTokens = text.components(separatedBy: .whitespacesAndNewlines)
            let extra = sanitizeTokens(secondaryTokens, existing: Set(cleaned))
            cleaned.append(contentsOf: extra)
        }
        
        return Array(cleaned.prefix(3))
    }
    
    private func cacheKey(for context: String) -> String {
        context.suffix(128).lowercased()
    }
    
    private func cachedPredictions(for key: String) -> [String]? {
        guard let entry = cache[key] else { return nil }
        if Date().timeIntervalSince(entry.timestamp) > cacheTTL {
            cache.removeValue(forKey: key)
            return nil
        }
        return entry.predictions
    }
    
    private func cache(predictions: [String], for key: String) {
        guard !predictions.isEmpty else { return }
        if cache.count >= maxEntries {
            cache.remove(at: cache.startIndex)
        }
        cache[key] = CacheEntry(predictions: predictions, timestamp: Date())
    }
    
    private func sanitizeTokens(_ tokens: [String], existing: Set<String> = []) -> [String] {
        var seen = existing
        var cleaned: [String] = []
        for token in tokens {
            guard let word = sanitizeWord(token) else { continue }
            guard !seen.contains(word) else { continue }
            seen.insert(word)
            cleaned.append(word)
            if cleaned.count == 3 { break }
        }
        return cleaned
    }
    
    private func sanitizeWord(_ token: String) -> String? {
        let lowercased = token.lowercased()
        var builder = ""
        var hasLetter = false
        for character in lowercased {
            if character.isWhitespace {
                break
            }
            if character.isLetter || character.isNumber {
                builder.append(character)
                hasLetter = true
            } else if character == "'" && hasLetter {
                builder.append(character)
            } else if builder.isEmpty {
                continue
            } else {
                break
            }
        }
        
        builder = builder.trimmingCharacters(in: CharacterSet(charactersIn: "'"))
        if builder.count > 18 {
            builder = String(builder.prefix(18))
        }
        return builder.isEmpty ? nil : builder
    }
}
