import Foundation
import os

protocol FoodAnalysisServiceProtocol {
    func analyzeFood(image: Data, foodName: String, mode: FoodCaptureMode) async throws -> FoodScan
}

extension FoodAnalysisServiceProtocol {
    /// Back-compat shim for callers that only know about photo mode.
    func analyzeFood(image: Data, foodName: String) async throws -> FoodScan {
        try await analyzeFood(image: image, foodName: foodName, mode: .photo)
    }
}

enum FoodAnalysisError: LocalizedError {
    case networkError
    case invalidResponse
    case rateLimited
    case invalidAPIKey
    case noFoodDetected

    var errorDescription: String? {
        switch self {
        case .networkError: return "Check your connection and try again."
        case .invalidResponse: return "Couldn't analyze this food, try a clearer photo."
        case .rateLimited: return "Too many requests, try again in a moment."
        case .invalidAPIKey: return "API configuration error."
        case .noFoodDetected: return "No food detected — try pointing the camera at your meal 🍽"
        }
    }
}

final class FoodAnalysisService: FoodAnalysisServiceProtocol {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    private let log = GlowbiteLog.foodAPI
    private let offClient: OpenFoodFactsClientProtocol

    init(apiKey: String = Config.openAIAPIKey,
         offClient: OpenFoodFactsClientProtocol = OpenFoodFactsClient()) {
        self.apiKey = apiKey
        self.offClient = offClient
    }

    func analyzeFood(image: Data, foodName: String, mode: FoodCaptureMode) async throws -> FoodScan {
        log.info("Image prepared, size=\(image.count) bytes, foodName=\(foodName), mode=\(mode.rawValue, privacy: .public)")

        let base64Image = image.base64EncodedString()
        let systemPrompt = Self.systemPrompt(for: mode, userFoodName: foodName)
        let userText = Self.userText(for: mode, foodName: foodName)

        let requestBody: [String: Any] = [
            "model": "gpt-4.1",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": [
                    ["type": "text", "text": userText],
                    ["type": "image_url", "image_url": [
                        "url": "data:image/jpeg;base64,\(base64Image)",
                        "detail": mode == .label ? "high" : "low"
                    ]]
                ] as [Any]]
            ],
            "max_tokens": 1000,
            "temperature": 0.3,
            "response_format": ["type": "json_object"]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: requestBody)
        log.info("Request serialized, payloadSize=\(jsonData.count) bytes")

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response): (Data, URLResponse)
        do {
            log.info("Request dispatched to OpenAI")
            (data, response) = try await URLSession.shared.data(for: request)
            log.info("Response received, size=\(data.count) bytes")
        } catch {
            log.error("Network error: \(error.localizedDescription)")
            throw FoodAnalysisError.networkError
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            log.error("Response is not HTTPURLResponse")
            throw FoodAnalysisError.invalidResponse
        }

        log.info("HTTP status=\(httpResponse.statusCode)")

        switch httpResponse.statusCode {
        case 200: break
        case 401: throw FoodAnalysisError.invalidAPIKey
        case 429: throw FoodAnalysisError.rateLimited
        default: throw FoodAnalysisError.networkError
        }

        let (scan, detectedBarcode) = try parseResponse(data, imageData: image)

        // Barcode mode: enrich with Open Food Facts when we have a code. If the
        // network call fails we silently keep the GPT-estimated values.
        if mode == .barcode, let code = detectedBarcode,
           let off = await offClient.lookup(barcode: code) {
            log.info("Enriched barcode=\(code, privacy: .public) via OFF")
            return Self.merge(scan: scan, with: off)
        }

        return scan
    }

    private func parseResponse(_ data: Data, imageData: Data) throws -> (FoodScan, String?) {
        log.info("Parsing response")

        let json: [String: Any]
        do {
            guard let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                throw FoodAnalysisError.invalidResponse
            }
            json = parsed
        } catch {
            log.error("Failed to parse API response JSON")
            throw FoodAnalysisError.invalidResponse
        }

        guard let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            if let error = json["error"] as? [String: Any],
               let errorMessage = error["message"] as? String {
                log.error("API error: \(errorMessage)")
            }
            throw FoodAnalysisError.invalidResponse
        }

        let cleaned = content
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let analysis: [String: Any]
        do {
            guard let parsed = try JSONSerialization.jsonObject(with: cleaned.data(using: .utf8) ?? Data()) as? [String: Any] else {
                log.error("Failed to parse content JSON")
                throw FoodAnalysisError.invalidResponse
            }
            analysis = parsed
        } catch is FoodAnalysisError {
            throw FoodAnalysisError.invalidResponse
        } catch {
            log.error("Failed to parse content JSON")
            throw FoodAnalysisError.invalidResponse
        }

        let foodName = analysis["food_name"] as? String ?? "Unknown food"
        let skinImpactScore = (analysis["skin_impact_score"] as? Double)
            ?? (analysis["skin_impact_score"] as? Int).map(Double.init)
            ?? 5.0
        let benefits = analysis["benefits"] as? [String] ?? []

        let calories: Int
        if let c = analysis["calories"] as? Int {
            calories = c
        } else if let c = analysis["calories"] as? Double {
            calories = Int(c)
        } else {
            calories = 0
        }

        let protein = (analysis["protein"] as? Double) ?? (analysis["protein"] as? Int).map(Double.init) ?? 0
        let fat = (analysis["fat"] as? Double) ?? (analysis["fat"] as? Int).map(Double.init) ?? 0
        let carbs = (analysis["carbs"] as? Double) ?? (analysis["carbs"] as? Int).map(Double.init) ?? 0
        let fiber = (analysis["fiber"] as? Double) ?? (analysis["fiber"] as? Int).map(Double.init) ?? 0
        let sugar = (analysis["sugar"] as? Double) ?? (analysis["sugar"] as? Int).map(Double.init) ?? 0
        let sodium = (analysis["sodium"] as? Double) ?? (analysis["sodium"] as? Int).map(Double.init) ?? 0
        let aiTip = analysis["ai_tip"] as? String
        let barcode = (analysis["barcode"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)

        let skinEffectsArray = analysis["skin_effects"] as? [[String: Any]] ?? []
        let skinEffects: [SkinEffect] = skinEffectsArray.compactMap { dict in
            guard let typeStr = dict["metric_type"] as? String,
                  let metricType = SkinMetricType(rawValue: typeStr),
                  let dirStr = dict["direction"] as? String,
                  let direction = Trend(rawValue: dirStr) else { return nil }
            let description = dict["description"] as? String ?? ""
            return SkinEffect(metricType: metricType, direction: direction, description: description)
        }

        log.info("Response parsed, foodName=\(foodName), score=\(skinImpactScore), benefitCount=\(benefits.count)")

        // Reject if the AI detected no food in the image
        let nameLower = foodName.lowercased()
        if skinImpactScore <= 0 || nameLower.contains("no food") || nameLower.contains("not visible") || nameLower.contains("no meal") {
            log.notice("No food detected in image, rejecting scan")
            throw FoodAnalysisError.noFoodDetected
        }

        let scan = FoodScan(
            name: foodName,
            skinImpactScore: skinImpactScore,
            calories: max(0, calories),
            protein: max(0, protein),
            fat: max(0, fat),
            carbs: max(0, carbs),
            fiber: max(0, fiber),
            sugar: max(0, sugar),
            sodium: max(0, sodium),
            benefits: benefits,
            skinEffects: skinEffects,
            photoData: nil,
            aiTip: aiTip
        )

        let normalisedBarcode: String?
        if let b = barcode, !b.isEmpty, b.allSatisfy({ $0.isNumber }) {
            normalisedBarcode = b
        } else {
            normalisedBarcode = nil
        }

        return (scan, normalisedBarcode)
    }

    // MARK: - Mode-specific Prompts

    private static func systemPrompt(for mode: FoodCaptureMode, userFoodName: String) -> String {
        switch mode {
        case .photo:
            return Self.photoPrompt(userFoodName: userFoodName)
        case .barcode:
            return Self.barcodePrompt()
        case .label:
            return Self.labelPrompt()
        }
    }

    private static func userText(for mode: FoodCaptureMode, foodName: String) -> String {
        switch mode {
        case .photo:   return "I'm eating: \(foodName). Please analyze this meal."
        case .barcode: return "Here's a barcode on a packaged food. Identify the product and score it for skin health."
        case .label:   return "Here's a nutrition label. Read the values and score this food for skin health."
        }
    }

    private static let commonScoringGuide = """
    Scoring guide for skin_impact_score (1-10):
      9-10: Superfoods for skin (salmon, avocado, berries, leafy greens, nuts)
      7-8: Good for skin (eggs, sweet potato, olive oil, yogurt, whole grains)
      5-6: Neutral (chicken breast, rice, pasta, bread, most fruits)
      3-4: Mildly bad (fried foods, white sugar, processed snacks)
      1-2: Bad for skin (candy, soda, alcohol, excessive dairy, fast food)

    For skin_effects, use these metric_type values only: hydration, acne, dark_spots, redness, texture, pores, wrinkles
    For direction, use only: improved, worsened

    IMPORTANT nutrition fields:
    - fiber: grams of dietary fiber
    - sugar: grams of total sugar (added + natural)
    - sodium: in GRAMS (not milligrams). E.g., 1500mg = 1.5g. A typical meal has 0.3-1.5g sodium.

    Always provide at least 2 benefits and 2 skin_effects. Return ONLY valid JSON, no markdown.
    """

    private static func photoPrompt(userFoodName: String) -> String {
        """
        You are a nutrition and skin health expert. The user has taken a photo of their meal and identified it as "\(userFoodName)".

        Analyze this food image and provide a detailed assessment of its impact on skin health.

        Return ONLY valid JSON in this exact format:
        {
          "food_name": "Confirmed or corrected food name",
          "skin_impact_score": 7.5,
          "calories": 480,
          "protein": 35.0,
          "fat": 22.0,
          "carbs": 38.0,
          "fiber": 6.0,
          "sugar": 12.0,
          "sodium": 0.62,
          "benefits": ["..."],
          "skin_effects": [
            {"metric_type": "hydration", "direction": "improved", "description": "..."}
          ],
          "ai_tip": "..."
        }

        \(commonScoringGuide)

        Be accurate with all nutrition estimates based on the photo and portion size. If the food photo doesn't match the name, use what you see in the photo.
        """
    }

    private static func barcodePrompt() -> String {
        """
        You are a nutrition and skin health expert. The user has photographed a barcode on a packaged food product.

        Step 1: Read the barcode digits if they are legible in the image.
        Step 2: Identify the product from the barcode, the packaging, or any visible branding.
        Step 3: Estimate typical nutrition values per serving for that product and assess its impact on skin health.

        Return ONLY valid JSON in this exact format:
        {
          "food_name": "Confirmed product name (include brand if visible)",
          "barcode": "8-13 digit UPC/EAN string, or empty string if unreadable",
          "skin_impact_score": 4.0,
          "calories": 180,
          "protein": 2.0,
          "fat": 9.0,
          "carbs": 24.0,
          "fiber": 1.0,
          "sugar": 18.0,
          "sodium": 0.15,
          "benefits": ["..."],
          "skin_effects": [
            {"metric_type": "acne", "direction": "worsened", "description": "..."}
          ],
          "ai_tip": "..."
        }

        \(commonScoringGuide)

        If the barcode is unreadable AND the packaging gives no product hint, set food_name to "Packaged product" and estimate typical packaged-snack values with a skin_impact_score of 4.
        """
    }

    private static func labelPrompt() -> String {
        """
        You are a nutrition and skin health expert. The user has photographed the nutrition facts label on a packaged food.

        Step 1: Read the label's nutrition values carefully — pay attention to serving size and units (mg vs g).
        Step 2: Identify the product name from the label or packaging.
        Step 3: Using those exact nutrition values, assess the product's impact on skin health.

        Return ONLY valid JSON in this exact format:
        {
          "food_name": "Product name from the label",
          "skin_impact_score": 6.0,
          "calories": 230,
          "protein": 8.0,
          "fat": 11.0,
          "carbs": 26.0,
          "fiber": 3.0,
          "sugar": 6.0,
          "sodium": 0.42,
          "benefits": ["..."],
          "skin_effects": [
            {"metric_type": "texture", "direction": "improved", "description": "..."}
          ],
          "ai_tip": "..."
        }

        \(commonScoringGuide)

        Use the exact numeric values from the label — do not estimate when the label has the answer. Convert milligrams to grams for sodium.
        """
    }

    // MARK: - Open Food Facts Merge

    /// Replace GPT's nutrition estimates with Open Food Facts data when
    /// available. GPT-derived benefits, skin effects, scoring, and tip are kept.
    private static func merge(scan: FoodScan, with off: OpenFoodFactsProduct) -> FoodScan {
        let merged = FoodScan(
            id: scan.id,
            name: off.brand.map { "\($0) \(off.productName)" } ?? off.productName,
            skinImpactScore: scan.skinImpactScore,
            calories: off.calories ?? scan.calories,
            protein: off.proteinGrams ?? scan.protein,
            fat: off.fatGrams ?? scan.fat,
            carbs: off.carbsGrams ?? scan.carbs,
            fiber: off.fiberGrams ?? scan.fiber,
            sugar: off.sugarGrams ?? scan.sugar,
            sodium: off.sodiumGrams ?? scan.sodium,
            benefits: scan.benefits,
            skinEffects: scan.skinEffects,
            photoData: scan.photoData,
            aiTip: scan.aiTip,
            createdAt: scan.createdAt
        )
        return merged
    }
}
