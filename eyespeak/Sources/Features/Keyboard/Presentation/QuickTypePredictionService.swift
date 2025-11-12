import Foundation
import NaturalLanguage

#if canImport(FoundationModels)
import FoundationModels
#endif

actor QuickTypePredictionService {
    private struct CacheEntry {
        let value: [String]
        let timestamp: Date
    }
    
    private struct PredictionCache {
        private var storage: [String: CacheEntry] = [:]
        private let ttl: TimeInterval
        private let maxEntries: Int
        
        init(maxEntries: Int = 64, ttl: TimeInterval = 10) {
            self.maxEntries = maxEntries
            self.ttl = ttl
        }
        
        mutating func value(for key: String) -> [String]? {
            guard let entry = storage[key] else { return nil }
            if Date().timeIntervalSince(entry.timestamp) > ttl {
                storage.removeValue(forKey: key)
                return nil
            }
            return entry.value
        }
        
        mutating func insert(_ value: [String], for key: String) {
            if storage.count >= maxEntries {
                storage.remove(at: storage.startIndex)
            }
            storage[key] = CacheEntry(value: value, timestamp: Date())
        }
    }
    
    private var cache = PredictionCache()
    private var trigramModel = TrigramLanguageModel()
    private let defaultPredictions = ["I", "You", "We"]
    
    #if canImport(FoundationModels)
    private var quickTypeSession: LanguageModelSession?
    #endif
    private let backstopNextWords = ["you", "i", "we", "please", "thanks"]
    
    init() {
        #if canImport(FoundationModels)
        Task {
            await setupAppleIntelligenceSession()
        }
        #endif
    }
    
    func predictions(for text: String) async -> [String] {
        let context = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let values = await nextWordPredictions(context: context)
        return values.isEmpty ? defaultPredictions : values
    }
    
    func learn(from text: String) {
        trigramModel.learn(from: text)
    }
    
    private func nextWordPredictions(context: String) async -> [String] {
        let normalized = context.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = normalized.suffix(64).lowercased()
        if let cached = cache.value(for: key) {
            return cached
        }
        
        var results: [String] = []
        let ai = await aiNextWordSuggestions(for: normalized)
        mergeUnique(&results, from: ai)
        
        if results.count < 3 {
            let trigram = trigramModel.nextWords(after: normalized)
            mergeUnique(&results, from: trigram)
        }
        
        if results.count < 3 {
            mergeUnique(&results, from: backstopNextWords)
        }
        
        trigramModel.prefetch(context: normalized, suggestions: results)
        
        let final = Array(results.prefix(3))
        if !final.isEmpty {
            cache.insert(final, for: key)
        }
        return final
    }
    
    private func mergeUnique(_ base: inout [String], from candidates: [String]) {
        for candidate in candidates {
            let trimmed = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !base.contains(where: { $0.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                base.append(trimmed)
            }
            if base.count == 3 { break }
        }
    }
    
    #if canImport(FoundationModels)
    private func setupAppleIntelligenceSession() async {
        guard quickTypeSession == nil else { return }
        do {
            let instructions = """
            You predict the next word someone might type on an assistive keyboard.
            When you respond, output three lowercase options separated by commas (word1, word2, word3) with no explanation.
            Favor short, high-confidence words that sound natural with the provided context.
            """
            quickTypeSession = try LanguageModelSession(instructions: instructions)
        } catch {
            quickTypeSession = nil
        }
    }
    #endif
    
    private func aiNextWordSuggestions(for context: String) async -> [String] {
        let prompt = """
        Context: \(context)
        Predict 3 likely next words that follow naturally.
        Return format: word1, word2, word3
        """
        return await aiListResponse(for: prompt)
    }
    
    private func aiListResponse(for prompt: String) async -> [String] {
        #if canImport(FoundationModels)
        guard let session = quickTypeSession else { return [] }
        do {
            let response = try await session.respond(to: prompt)
            let separators = CharacterSet(charactersIn: ",\n")
            let tokens = response.content
                .components(separatedBy: separators)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return Array(tokens.prefix(3))
        } catch {
            return []
        }
        #else
        return []
        #endif
    }
}

// MARK: - Lightweight Trigram Language Model

private struct TrigramLanguageModel {
    private var userNextWordCounts: [String: [String: Int]] = [:]
    private var userWordFrequency: [String: Int] = [:]
    private let storage = UserDefaults.standard
    private let nextWordStorageKey = "QuickTypePredictionService.userNext"
    private let frequencyStorageKey = "QuickTypePredictionService.userFreq"
    private var tokenizer = NLTokenizer(unit: .word)
    
    private let seededNextWords: [String: [String]] = [
        "i need": ["help", "water", "rest"],
        "i want": ["to", "some", "help"],
        "can you": ["help", "call", "come"],
        "how are": ["you", "things", "we"],
        "thank you": ["so", "very", "for"],
        "can we": ["go", "try", "rest"],
        "let me": ["know", "rest", "see"],
        "i am": ["tired", "okay", "ready"],
        "we are": ["ready", "here", "going"],
        "are you": ["okay", "there", "free"],
        "hello can": ["you", "i", "we"],
        "hello": ["there", "friend", "everyone"]
    ]
    
    init() {
        tokenizer.string = ""
        loadPersistedData()
    }
    
    mutating func learn(from text: String) {
        let tokens = tokenize(text)
        guard tokens.count >= 1 else { return }
        
        if tokens.count >= 3 {
            for index in 0..<(tokens.count - 2) {
                let key = "\(tokens[index]) \(tokens[index + 1])"
                let next = tokens[index + 2]
                incrementNextWord(key: key, next: next)
            }
        }
        for token in tokens {
            userWordFrequency[token, default: 0] += 1
        }
        
        persist()
    }
    
    mutating func nextWords(after context: String) -> [String] {
        let tokens = tokenize(context)
        guard !tokens.isEmpty else { return [] }
        var ordered: [String] = []
        if tokens.count >= 2 {
            let bigram = "\(tokens[tokens.count - 2]) \(tokens.last!)"
            ordered.append(contentsOf: rankedSuggestions(forKey: bigram))
        }
        if let last = tokens.last {
            ordered.append(contentsOf: rankedSuggestions(forKey: last))
        }
        return uniqueOrdered(ordered, limit: 3)
    }
    
    mutating func prefetch(context: String, suggestions: [String]) {
        let tokens = tokenize(context)
        guard !tokens.isEmpty else { return }
        let key: String
        if tokens.count >= 2 {
            key = "\(tokens[tokens.count - 2]) \(tokens.last!)"
        } else {
            key = tokens.last!
        }
        for suggestion in suggestions {
            incrementNextWord(key: key, next: suggestion.lowercased())
        }
    }
    
    private mutating func incrementNextWord(key: String, next: String) {
        guard !key.isEmpty else { return }
        if next.isEmpty {
            return
        }
        var bucket = userNextWordCounts[key.lowercased(), default: [:]]
        bucket[next, default: 0] += 1
        userNextWordCounts[key.lowercased()] = bucket
    }
    
    private func rankedSuggestions(forKey key: String) -> [String] {
        let lowerKey = key.lowercased()
        var pairs: [(String, Int)] = []
        if let map = userNextWordCounts[lowerKey] {
            pairs.append(contentsOf: map.map { ($0.key, $0.value) })
        }
        if let seeded = seededNextWords[lowerKey] {
            for (index, word) in seeded.enumerated() {
                let weight = max(1, seeded.count - index)
                pairs.append((word, weight))
            }
        }
        pairs.sort { $0.1 > $1.1 }
        return pairs.map { $0.0 }
    }
    
    private func tokenize(_ text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        let lower = text.lowercased()
        tokenizer.string = lower
        var tokens: [String] = []
        tokenizer.enumerateTokens(in: lower.startIndex..<lower.endIndex) { range, _ in
            let token = lower[range].trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            if !token.isEmpty {
                tokens.append(token)
            }
            return true
        }
        return tokens
    }
    
    private mutating func loadPersistedData() {
        let decoder = JSONDecoder()
        if let nextData = storage.data(forKey: nextWordStorageKey),
           let decodedNext = try? decoder.decode([String: [String: Int]].self, from: nextData) {
            userNextWordCounts = decodedNext
        }
        if let freqData = storage.data(forKey: frequencyStorageKey),
           let decodedFreq = try? decoder.decode([String: Int].self, from: freqData) {
            userWordFrequency = decodedFreq
        }
    }
    
    private func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(userNextWordCounts) {
            storage.set(data, forKey: nextWordStorageKey)
        }
        if let freq = try? encoder.encode(userWordFrequency) {
            storage.set(freq, forKey: frequencyStorageKey)
        }
    }
}

private func uniqueOrdered(_ values: [String], limit: Int) -> [String] {
    var seen: Set<String> = []
    var result: [String] = []
    for value in values {
        let lower = value.lowercased()
        if !seen.contains(lower) {
            seen.insert(lower)
            result.append(value)
        }
        if result.count == limit { break }
    }
    return result
}
