//
//  GeminiAssistantClient.swift
//  FP.Studius
//

import Foundation

struct GeminiChatTurn {
    let role: String
    let text: String
}

enum GeminiAssistantError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case emptyResponse
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "Gemini API key not found."
        case .invalidURL:
            return "Gemini API URL could not be created."
        case .emptyResponse:
            return "Gemini returned an empty response."
        case .apiError(let message):
            return message
        }
    }
}

struct GeminiAssistantClient {
    private var apiKey: String? {
        infoString("GEMINI_API_KEY")
    }

    private var modelName: String {
        infoString("GEMINI_MODEL") ?? "gemini-2.0-flash"
    }

    func reply(for chat: [GeminiChatTurn], appContext: String? = nil) async throws -> String {
        guard let apiKey, !apiKey.isEmpty else {
            throw GeminiAssistantError.missingAPIKey
        }

        guard let url = makeURL(apiKey: apiKey) else {
            throw GeminiAssistantError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(makeRequest(chat: chat, appContext: appContext))

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse,
           !(200...299).contains(httpResponse.statusCode) {
            let message = decodeAPIError(from: data) ?? "Gemini request failed."
            throw GeminiAssistantError.apiError(message)
        }

        let responseBody = try JSONDecoder().decode(GeminiGenerateResponse.self, from: data)
        guard let text = responseBody.text, !text.isEmpty else {
            throw GeminiAssistantError.emptyResponse
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func infoString(_ key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else {
            return nil
        }

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func makeURL(apiKey: String) -> URL? {
        let modelPath = modelName.hasPrefix("models/") ? modelName : "models/\(modelName)"
        var components = URLComponents()
        components.scheme = "https"
        components.host = "generativelanguage.googleapis.com"
        components.path = "/v1beta/\(modelPath):generateContent"
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        return components.url
    }

    private func makeRequest(chat: [GeminiChatTurn], appContext: String?) -> GeminiGenerateRequest {
        let systemPrompt = """
        You are Studius Assistant, a friendly academic assistant inside an iOS app for a University of Westminster Software Engineering student.
        Help with app usage, deadlines, classes, Software Engineering topics, programming, databases, web, mobile, testing, cyber security, and final year project planning.
        Keep answers practical, clear, and not too long. Do not pretend you changed app data unless the app already confirmed it.

        \(appContext ?? "")
        """

        return GeminiGenerateRequest(
            systemInstruction: GeminiContent(text: systemPrompt),
            contents: chat.map { turn in
                GeminiContent(role: turn.role, text: turn.text)
            },
            generationConfig: GeminiGenerationConfig(temperature: 0.7)
        )
    }

    private func decodeAPIError(from data: Data) -> String? {
        try? JSONDecoder().decode(GeminiErrorResponse.self, from: data).error.message
    }
}

private struct GeminiGenerateRequest: Encodable {
    let systemInstruction: GeminiContent
    let contents: [GeminiContent]
    let generationConfig: GeminiGenerationConfig
}

private struct GeminiGenerationConfig: Encodable {
    let temperature: Double
}

private struct GeminiContent: Codable {
    let role: String?
    let parts: [GeminiPart]

    init(role: String? = nil, text: String) {
        self.role = role
        self.parts = [GeminiPart(text: text)]
    }
}

private struct GeminiPart: Codable {
    let text: String?
}

private struct GeminiGenerateResponse: Decodable {
    let candidates: [GeminiCandidate]?

    var text: String? {
        candidates?.first?.content.parts.compactMap(\.text).joined()
    }
}

private struct GeminiCandidate: Decodable {
    let content: GeminiContent
}

private struct GeminiErrorResponse: Decodable {
    let error: GeminiAPIError
}

private struct GeminiAPIError: Decodable {
    let message: String
}
