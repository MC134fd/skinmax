import Foundation
import os

protocol SkinAnalysisServiceProtocol {
    func analyzeSkin(image: Data) async throws -> SkinScan
}

enum SkinAnalysisError: LocalizedError {
    case networkError
    case invalidResponse
    case rateLimited
    case invalidAPIKey
    case malformedAnalysis(String)

    var errorDescription: String? {
        switch self {
        case .networkError: return "Couldn't reach our AI. Check your connection."
        case .invalidResponse: return "Analysis failed. Please try again."
        case .rateLimited: return "Too many scans. Try again in a minute."
        case .invalidAPIKey: return "Invalid API key. Check your Config.swift."
        case .malformedAnalysis: return "Analysis failed. Please try again."
        }
    }
}

final class SkinAnalysisService: SkinAnalysisServiceProtocol {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let log = GlowbiteLog.skinAPI

    // All metric types the prompt must return, matching the app enum
    private static let requiredMetricTypes: Set<String> = [
        "hydration", "acne", "dark_spots", "redness", "texture", "pores", "wrinkles", "elasticity"
    ]
    private static let validSeverities: Set<String> = ["minimal", "mild", "moderate", "severe"]
    private static let validQualities: Set<String> = ["good", "usable", "poor"]
    private static let validQualityFlags: Set<String> = [
        "uneven_lighting", "too_dark", "too_bright", "blurry", "partial_face", "obstructed", "too_far", "too_close"
    ]

    private let systemPrompt = """
    You are a dermatology-focused skin condition assessment tool for the Glowbite wellness app. The user has voluntarily submitted a close-up photo of their own skin for a general wellness check. You are NOT identifying any person — you are assessing visible skin characteristics only (texture, tone, hydration signs, blemishes, pore visibility, etc.), similar to what a skincare product recommendation quiz would evaluate.

    IMPORTANT: Use objective, evidence-based phrasing only. Do not diagnose conditions or make medical claims.

    ## SCORING RUBRIC — apply strictly per metric

    ### hydration (higher = more hydrated)
    Evidence to look for: surface sheen, dry patches, flakiness, skin plumpness, fine dehydration lines.
    - 70-100 (Good): Skin appears plump with healthy sheen, no visible dry patches or flaking.
    - 40-69 (Fair): Some dull areas or minor dry patches visible, slight lack of sheen.
    - 0-39 (Needs work): Widespread dryness, visible flaking, tight-looking skin, prominent dehydration lines.

    ### acne (higher = clearer skin)
    Evidence to look for: active blemishes, whiteheads, blackheads, cystic bumps, post-inflammatory marks.
    - 70-100 (Good): No active blemishes or only 1-2 minor spots.
    - 40-69 (Fair): Several visible blemishes (3-8), mostly small, some post-inflammatory marks.
    - 0-39 (Needs work): Numerous active blemishes (>8), cystic or inflamed bumps, widespread breakout.

    ### dark_spots (higher = more even tone)
    Evidence to look for: hyperpigmentation patches, sun spots, post-inflammatory marks, melasma-like patches, uneven tone.
    - 70-100 (Good): Even skin tone, no notable discoloration patches.
    - 40-69 (Fair): A few visible darker patches or mild uneven tone.
    - 0-39 (Needs work): Prominent hyperpigmentation, multiple dark patches, very uneven tone.

    ### redness (higher = calmer skin)
    Evidence to look for: flushing, blotchiness, visible capillaries, irritation, inflammatory patches.
    - 70-100 (Good): Even tone without notable redness or flushing.
    - 40-69 (Fair): Some pinkness or mild blotchiness in limited areas.
    - 0-39 (Needs work): Widespread redness, visible irritation, prominent flushing across multiple zones.

    ### texture (higher = smoother)
    Evidence to look for: surface roughness, bumpy texture, uneven grain, milia, keratosis-like bumps.
    - 70-100 (Good): Smooth, even surface with fine grain.
    - 40-69 (Fair): Some rough patches or mildly uneven surface in places.
    - 0-39 (Needs work): Noticeably rough, bumpy, or uneven surface across broad areas.

    ### pores (higher = less visible)
    Evidence to look for: pore size visibility especially on nose/cheeks/forehead, congested pores, enlarged appearance.
    - 70-100 (Good): Pores barely visible, refined appearance.
    - 40-69 (Fair): Pores moderately visible in T-zone or cheeks.
    - 0-39 (Needs work): Large, prominent pores across multiple facial zones, congested appearance.

    ### wrinkles (higher = smoother)
    Evidence to look for: fine lines around eyes/mouth/forehead, crow's feet, nasolabial folds, forehead creases.
    - 70-100 (Good): Minimal to no visible fine lines.
    - 40-69 (Fair): Some fine lines visible in expression areas.
    - 0-39 (Needs work): Deep or numerous lines across multiple areas.

    ### elasticity (higher = firmer)
    Evidence to look for: skin firmness appearance, sagging, jawline definition, under-eye hollowing, nasolabial depth.
    - 70-100 (Good): Skin appears firm and well-supported, defined contours.
    - 40-69 (Fair): Mild loss of firmness, slightly softened contours.
    - 0-39 (Needs work): Noticeable sagging, poorly defined contours, significant laxity.

    ## SEVERITY MAPPING
    - Score 70-100 → "minimal"
    - Score 40-69 → "mild" or "moderate" (use "mild" for 55-69, "moderate" for 40-54)
    - Score 0-39 → "severe"

    ## CONFIDENCE
    Rate your confidence (0.0-1.0) in each metric based on image clarity for that area:
    - 0.8-1.0: Clear view, high certainty
    - 0.5-0.79: Partial view or suboptimal lighting for this area
    - Below 0.5: Poor visibility, score is a rough estimate

    ## IMAGE QUALITY
    Assess the overall image quality:
    - "good": Clear, well-lit, full face visible
    - "usable": Acceptable but not ideal (minor issues)
    - "poor": Significant issues affecting assessment accuracy

    Flag any quality issues from: uneven_lighting, too_dark, too_bright, blurry, partial_face, obstructed, too_far, too_close.

    ## GLOW SCORE
    The glow_score is a weighted composite (0-100). Weight metrics roughly: hydration 15%, acne 15%, texture 15%, redness 12%, dark_spots 12%, pores 12%, wrinkles 10%, elasticity 9%. Round to nearest integer.

    ## OUTPUT REQUIREMENTS
    - Return ALL 8 metrics exactly once: hydration, acne, dark_spots, redness, texture, pores, wrinkles, elasticity.
    - Each metric must include: type, score, severity, confidence, evidence (2-4 short findings), description (1 sentence).
    - trend is always "stable" for single-scan analysis.
    - ai_insight: 2-3 sentences of actionable skincare advice based on the weakest metrics. Suggest specific foods or habits.
    - overall_message: Short encouraging summary (1 sentence).
    - Return ONLY valid JSON matching the required schema.
    """

    private let jsonSchema: [String: Any] = [
        "type": "json_schema",
        "json_schema": [
            "name": "skin_analysis",
            "strict": true,
            "schema": [
                "type": "object",
                "required": ["glow_score", "metrics", "ai_insight", "overall_message", "image_quality", "quality_flags"],
                "additionalProperties": false,
                "properties": [
                    "glow_score": ["type": "integer"],
                    "image_quality": ["type": "string", "enum": ["good", "usable", "poor"]],
                    "quality_flags": [
                        "type": "array",
                        "items": [
                            "type": "string",
                            "enum": ["uneven_lighting", "too_dark", "too_bright", "blurry", "partial_face", "obstructed", "too_far", "too_close"]
                        ]
                    ],
                    "ai_insight": ["type": "string"],
                    "overall_message": ["type": "string"],
                    "metrics": [
                        "type": "array",
                        "items": [
                            "type": "object",
                            "required": ["type", "score", "severity", "confidence", "evidence", "description", "trend"],
                            "additionalProperties": false,
                            "properties": [
                                "type": [
                                    "type": "string",
                                    "enum": ["hydration", "acne", "dark_spots", "redness", "texture", "pores", "wrinkles", "elasticity"]
                                ],
                                "score": ["type": "integer"],
                                "severity": ["type": "string", "enum": ["minimal", "mild", "moderate", "severe"]],
                                "confidence": ["type": "number"],
                                "evidence": [
                                    "type": "array",
                                    "items": ["type": "string"]
                                ],
                                "description": ["type": "string"],
                                "trend": ["type": "string", "enum": ["stable", "improved", "worsened"]]
                            ]
                        ]
                    ]
                ]
            ] as [String: Any]
        ] as [String: Any]
    ]

    init(apiKey: String = Config.openAIAPIKey) {
        self.apiKey = apiKey
    }

    func analyzeSkin(image: Data) async throws -> SkinScan {
        log.info("Image prepared, size=\(image.count) bytes")

        let base64Image = image.base64EncodedString()

        let requestBody: [String: Any] = [
            "model": "gpt-4.1",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["type": "text", "text": "Assess the visible skin condition in this close-up photo for a skincare wellness check."],
                    ["type": "image_url", "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)",
                        "detail": "high"
                    ]]
                ] as [Any]]
            ],
            "max_tokens": 1200,
            "temperature": 0.1,
            "response_format": jsonSchema
        ]

        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: requestBody)
            log.info("Request serialized, payloadSize=\(jsonData.count) bytes")
        } catch {
            log.error("Failed to serialize request: \(error.localizedDescription)")
            throw SkinAnalysisError.invalidResponse
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 60

        let (data, response): (Data, URLResponse)
        do {
            log.info("Request dispatched to OpenAI")
            (data, response) = try await URLSession.shared.data(for: request)
            log.info("Response received, size=\(data.count) bytes")
        } catch {
            log.error("Network error: \(error.localizedDescription)")
            throw SkinAnalysisError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            log.error("Response is not HTTPURLResponse")
            throw SkinAnalysisError.invalidResponse
        }

        log.info("HTTP status=\(httpResponse.statusCode)")

        if httpResponse.statusCode != 200 {
            log.error("Non-200 response, status=\(httpResponse.statusCode)")
        }

        switch httpResponse.statusCode {
        case 200: break
        case 401: throw SkinAnalysisError.invalidAPIKey
        case 429: throw SkinAnalysisError.rateLimited
        default: throw SkinAnalysisError.networkError
        }

        return try parseResponse(data)
    }

    // MARK: - Response Parsing & Validation

    private func parseResponse(_ data: Data) throws -> SkinScan {
        log.info("Parsing response")

        let content = try extractContent(from: data)
        log.info("Content extracted, length=\(content.count)")

        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let contentData = cleaned.data(using: .utf8),
              let analysis = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            log.error("Failed to parse content as JSON")
            throw SkinAnalysisError.invalidResponse
        }

        log.info("Parsed analysis, keys=\(Array(analysis.keys).sorted())")

        let glowScore = try validateGlowScore(analysis)
        let metrics = try validateMetrics(analysis)
        let aiInsight = try validateRequiredString(analysis, key: "ai_insight")
        let overallMessage = try validateRequiredString(analysis, key: "overall_message")

        // Log quality info (not persisted but useful for debugging)
        if let quality = analysis["image_quality"] as? String {
            log.info("Image quality=\(quality)")
        }
        if let flags = analysis["quality_flags"] as? [String], !flags.isEmpty {
            log.info("Quality flags=\(flags)")
        }

        log.info("Response parsed successfully, glowScore=\(glowScore), metricCount=\(metrics.count)")

        return SkinScan(
            glowScore: Double(glowScore),
            metrics: metrics,
            aiInsight: aiInsight,
            overallMessage: overallMessage
        )
    }

    private func extractContent(from data: Data) throws -> String {
        let json: [String: Any]
        do {
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw SkinAnalysisError.invalidResponse
            }
            json = parsed
        } catch is SkinAnalysisError {
            throw SkinAnalysisError.invalidResponse
        } catch {
            log.error("JSON parse error: \(error.localizedDescription)")
            throw SkinAnalysisError.invalidResponse
        }

        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            log.error("Failed to extract content from choices, keys=\(Array(json.keys))")
            if let error = json["error"] as? [String: Any],
               let msg = error["message"] as? String {
                log.error("API error message: \(msg)")
            }
            throw SkinAnalysisError.invalidResponse
        }

        return content
    }

    private func validateGlowScore(_ analysis: [String: Any]) throws -> Int {
        let score: Int
        if let g = analysis["glow_score"] as? Int {
            score = g
        } else if let g = analysis["glow_score"] as? Double {
            score = Int(g)
        } else {
            log.error("Missing or invalid glow_score")
            throw SkinAnalysisError.malformedAnalysis("Missing glow_score")
        }

        guard (0...100).contains(score) else {
            log.error("glow_score out of range: \(score)")
            throw SkinAnalysisError.malformedAnalysis("glow_score \(score) out of range 0-100")
        }

        return score
    }

    private func validateRequiredString(_ analysis: [String: Any], key: String) throws -> String {
        guard let value = analysis[key] as? String, !value.isEmpty else {
            log.error("Missing or empty required field: \(key)")
            throw SkinAnalysisError.malformedAnalysis("Missing \(key)")
        }
        return value
    }

    private func validateMetrics(_ analysis: [String: Any]) throws -> [SkinMetric] {
        guard let metricsArray = analysis["metrics"] as? [[String: Any]] else {
            log.error("Missing metrics array")
            throw SkinAnalysisError.malformedAnalysis("Missing metrics array")
        }

        var metrics: [SkinMetric] = []
        var seenTypes: Set<String> = []

        for dict in metricsArray {
            let metric = try validateSingleMetric(dict)
            let typeStr = metric.type.rawValue

            guard !seenTypes.contains(typeStr) else {
                log.error("Duplicate metric type: \(typeStr)")
                throw SkinAnalysisError.malformedAnalysis("Duplicate metric: \(typeStr)")
            }
            seenTypes.insert(typeStr)
            metrics.append(metric)
        }

        // Verify all required types are present
        let missingTypes = Self.requiredMetricTypes.subtracting(seenTypes)
        guard missingTypes.isEmpty else {
            log.error("Missing metric types: \(missingTypes.sorted())")
            throw SkinAnalysisError.malformedAnalysis("Missing metrics: \(missingTypes.sorted().joined(separator: ", "))")
        }

        return metrics
    }

    private func validateSingleMetric(_ dict: [String: Any]) throws -> SkinMetric {
        // Type
        guard let typeStr = dict["type"] as? String,
              let type = SkinMetricType(rawValue: typeStr) else {
            let got = dict["type"] as? String ?? "nil"
            throw SkinAnalysisError.malformedAnalysis("Invalid metric type: \(got)")
        }

        // Score
        let score: Int
        if let s = dict["score"] as? Int { score = s }
        else if let s = dict["score"] as? Double { score = Int(s) }
        else { throw SkinAnalysisError.malformedAnalysis("Missing score for \(typeStr)") }

        guard (0...100).contains(score) else {
            throw SkinAnalysisError.malformedAnalysis("Score \(score) out of range for \(typeStr)")
        }

        // Severity
        guard let severity = dict["severity"] as? String,
              Self.validSeverities.contains(severity) else {
            throw SkinAnalysisError.malformedAnalysis("Invalid severity for \(typeStr)")
        }

        // Confidence
        let confidence: Double
        if let c = dict["confidence"] as? Double { confidence = c }
        else if let c = dict["confidence"] as? Int { confidence = Double(c) }
        else { throw SkinAnalysisError.malformedAnalysis("Missing confidence for \(typeStr)") }

        guard (0.0...1.0).contains(confidence) else {
            throw SkinAnalysisError.malformedAnalysis("Confidence \(confidence) out of range for \(typeStr)")
        }

        // Evidence
        guard let evidence = dict["evidence"] as? [String],
              evidence.count >= 2 && evidence.count <= 4 else {
            let count = (dict["evidence"] as? [String])?.count ?? 0
            throw SkinAnalysisError.malformedAnalysis("Expected 2-4 evidence items for \(typeStr), got \(count)")
        }

        // Description
        guard let description = dict["description"] as? String, !description.isEmpty else {
            throw SkinAnalysisError.malformedAnalysis("Missing description for \(typeStr)")
        }

        let trend = dict["trend"] as? String ?? "stable"

        return SkinMetric(
            type: type,
            score: Double(score),
            severity: severity,
            trend: trend,
            description: description,
            confidence: confidence,
            evidence: evidence
        )
    }
}
