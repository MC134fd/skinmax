import Foundation

protocol SkinAnalysisServiceProtocol {
    func analyzeSkin(image: Data) async throws -> SkinScan
}

enum SkinAnalysisError: LocalizedError {
    case networkError
    case invalidResponse
    case rateLimited
    case invalidAPIKey

    var errorDescription: String? {
        switch self {
        case .networkError: return "Couldn't reach our AI. Check your connection."
        case .invalidResponse: return "Analysis failed. Try again with better lighting."
        case .rateLimited: return "Too many scans. Try again in a minute."
        case .invalidAPIKey: return "Invalid API key. Check your Config.swift."
        }
    }
}

final class SkinAnalysisService: SkinAnalysisServiceProtocol {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    private let systemPrompt = """
    You are a skin health analysis AI for the Skinmax app. Analyze the face photo and return a JSON object with these exact fields:

    {
      "glow_score": <int 0-100, overall skin health score>,
      "metrics": [
        {
          "type": "hydration",
          "score": <int 0-100>,
          "severity": "<minimal|mild|moderate|severe>",
          "trend": "stable",
          "description": "<one sentence about this metric>"
        },
        {
          "type": "acne",
          "score": <int 0-100, higher = less acne = better>,
          "severity": "<minimal|mild|moderate|severe>",
          "trend": "stable",
          "description": "<one sentence>"
        },
        {
          "type": "dark_spots",
          "score": <int 0-100, higher = fewer spots = better>,
          "severity": "<minimal|mild|moderate|severe>",
          "trend": "stable",
          "description": "<one sentence>"
        },
        {
          "type": "redness",
          "score": <int 0-100, higher = less redness = better>,
          "severity": "<minimal|mild|moderate|severe>",
          "trend": "stable",
          "description": "<one sentence>"
        },
        {
          "type": "texture",
          "score": <int 0-100>,
          "severity": "<minimal|mild|moderate|severe>",
          "trend": "stable",
          "description": "<one sentence>"
        },
        {
          "type": "pores",
          "score": <int 0-100, higher = less visible = better>,
          "severity": "<minimal|mild|moderate|severe>",
          "trend": "stable",
          "description": "<one sentence>"
        },
        {
          "type": "wrinkles",
          "score": <int 0-100, higher = fewer wrinkles = better>,
          "severity": "<minimal|mild|moderate|severe>",
          "trend": "stable",
          "description": "<one sentence>"
        }
      ],
      "ai_insight": "<2-3 sentence personalized tip based on the worst metrics, suggest specific foods or habits that would help>",
      "overall_message": "<short encouraging message like 'Your skin is glowing!' or 'Room for improvement — let's work on it!'>"
    }

    Be encouraging but honest. Score realistically. Return ONLY valid JSON, no markdown.
    """

    init(apiKey: String = Config.openAIAPIKey) {
        self.apiKey = apiKey
    }

    func analyzeSkin(image: Data) async throws -> SkinScan {
        let base64Image = image.base64EncodedString()

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["type": "text", "text": "Analyze this face photo for skin health."],
                    ["type": "image_url", "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)",
                        "detail": "high"
                    ]]
                ] as [Any]]
            ],
            "max_tokens": 1000,
            "temperature": 0.3
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SkinAnalysisError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw SkinAnalysisError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200: break
        case 401: throw SkinAnalysisError.invalidAPIKey
        case 429: throw SkinAnalysisError.rateLimited
        default: throw SkinAnalysisError.networkError
        }

        return try parseResponse(data)
    }

    private func parseResponse(_ data: Data) throws -> SkinScan {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw SkinAnalysisError.invalidResponse
        }

        // Clean up content — sometimes GPT wraps in ```json ... ```
        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let analysisData = cleaned.data(using: .utf8),
              let analysis = try JSONSerialization.jsonObject(with: analysisData) as? [String: Any] else {
            throw SkinAnalysisError.invalidResponse
        }

        guard let glowScore = analysis["glow_score"] as? Int,
              let metricsArray = analysis["metrics"] as? [[String: Any]],
              let aiInsight = analysis["ai_insight"] as? String,
              let overallMessage = analysis["overall_message"] as? String else {
            throw SkinAnalysisError.invalidResponse
        }

        let metrics: [SkinMetric] = metricsArray.compactMap { dict in
            guard let typeStr = dict["type"] as? String,
                  let type = SkinMetricType(rawValue: typeStr),
                  let score = dict["score"] as? Int else { return nil }

            let severity = dict["severity"] as? String ?? "minimal"
            let trend = dict["trend"] as? String ?? "stable"
            let description = dict["description"] as? String ?? ""

            return SkinMetric(
                type: type,
                score: Double(score),
                severity: severity,
                trend: trend,
                description: description
            )
        }

        return SkinScan(
            glowScore: Double(glowScore),
            metrics: metrics,
            aiInsight: aiInsight,
            overallMessage: overallMessage
        )
    }
}
