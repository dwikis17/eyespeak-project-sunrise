import Foundation

/// Lightweight client for OpenAI chat completions used by the keyboard.
struct OpenAIConfig {
    var apiKey: String?
    var baseURL: URL
    var model: String
    var temperature: Double
    var maxTokens: Int

    init(
        apiKey: String? = OpenAIConfig.defaultAPIKey(),
        baseURL: URL = URL(string: "https://api.openai.com/v1")!,
        model: String = "gpt-4o-mini",
        temperature: Double = 0.35,
        maxTokens: Int = 64
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.model = model
        self.temperature = temperature
        self.maxTokens = maxTokens
    }

    var isConfigured: Bool {
        guard let key = apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            return false
        }
        return !key.isEmpty
    }

    private static func defaultAPIKey() -> String? {
        let environment = ProcessInfo.processInfo.environment
        let resolvedKey: String?
        if let envValue = environment["OPENAI_API_KEY"],
           !envValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resolvedKey = envValue
        } else if let plistValue = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
                  !plistValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            resolvedKey = plistValue
        } else {
            resolvedKey = nil
        }
        if resolvedKey == nil {
            print("⚠️ OPENAI_API_KEY not found in environment or Info.plist. Predictions disabled.")
        } else {
            print("🔑 OPENAI_API_KEY detected from \(environment["OPENAI_API_KEY"] != nil ? "environment" : "Info.plist")")
        }
        return resolvedKey
    }
}

actor OpenAIClient {
    enum ClientError: LocalizedError {
        case missingAPIKey
        case invalidResponse
        case emptyChoice
        case decodingFailed
        case api(String, statusCode: Int)

        var errorDescription: String? {
            switch self {
            case .missingAPIKey:
                return "Missing OPENAI_API_KEY. Add it to the environment or Info.plist."
            case .invalidResponse:
                return "Invalid response from OpenAI."
            case .emptyChoice:
                return "OpenAI returned no usable completion."
            case .decodingFailed:
                return "Failed to decode OpenAI response."
            case .api(let message, let statusCode):
                return "OpenAI \(statusCode): \(message)"
            }
        }
    }

    private let config: OpenAIConfig
    private let session: URLSession

    init(config: OpenAIConfig = OpenAIConfig(), session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    nonisolated var isConfigured: Bool {
        config.isConfigured
    }

    func complete(systemPrompt: String, userPrompt: String) async throws -> String {
        let apiKey = config.apiKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !apiKey.isEmpty else { throw ClientError.missingAPIKey }
        let start = Date()
        print("🔍 OpenAIClient: starting request model=\(config.model) temp=\(config.temperature) maxTokens=\(config.maxTokens)")
        print("🔍 OpenAIClient: system prompt chars=\(systemPrompt.count), user prompt chars=\(userPrompt.count)")

        var request = URLRequest(url: config.baseURL.appendingPathComponent("chat/completions"))
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let body = ChatCompletionRequest(
            model: config.model,
            messages: [
                .init(role: "system", content: systemPrompt),
                .init(role: "user", content: userPrompt)
            ],
            temperature: config.temperature,
            maxTokens: config.maxTokens
        )
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ClientError.invalidResponse
        }
        let elapsed = Date().timeIntervalSince(start)
        print("🔍 OpenAIClient: response status=\(httpResponse.statusCode) time=\(String(format: "%.2f", elapsed))s")

        guard (200...299).contains(httpResponse.statusCode) else {
            throw decodeAPIError(data: data, statusCode: httpResponse.statusCode)
        }

        let decoded = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let text = decoded.choices.first?.message.content?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            throw ClientError.emptyChoice
        }
        print("✅ OpenAIClient: received \(text.count) chars")
        return text
    }

    private func decodeAPIError(data: Data, statusCode: Int) -> ClientError {
        if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
            return ClientError.api(apiError.error.message, statusCode: statusCode)
        }
        return ClientError.api("status code \(statusCode)", statusCode: statusCode)
    }
}

private struct ChatCompletionRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int

    enum CodingKeys: String, CodingKey {
        case model
        case messages
        case temperature
        case maxTokens = "max_tokens"
    }
}

private struct ChatMessage: Codable {
    let role: String
    let content: String?
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: ChatMessage
    }
}

private struct APIErrorResponse: Decodable {
    struct ErrorBody: Decodable {
        let message: String
    }
    let error: ErrorBody
}
