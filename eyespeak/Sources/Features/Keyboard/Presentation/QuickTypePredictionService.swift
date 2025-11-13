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
        let separators = CharacterSet(charactersIn: ",\n")
        let tokens = text
            .components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Array(tokens.prefix(3))
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
}
