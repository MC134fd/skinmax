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
                        "detail": mode == .barcode ? "low" : "high"
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
            photoData: imageData,
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
    ACCURACY RULES — follow these exactly:
    1. Base every number on what is actually visible (or on the literal label text for label mode). Do NOT default to a canonical recipe.
    2. Estimate portion from visual cues: plate/bowl size, utensil, hand, packaging. If the portion looks small (≈0.5 serving), scale calories and macros DOWN. If it looks large (≈1.5–2 servings), scale UP.
    3. Only list ingredients you can actually see or that are clearly implied by the dish. Never invent toppings, sauces, or sides.
    4. If you cannot identify the food with reasonable confidence, return food_name = "Unclear food" with conservative neutral values (score ~5, calories ~300) rather than guessing.
    5. skin_impact_score must be a decimal with ONE meaningful digit (e.g. 6.5, 3.0, 8.5) — not always round numbers.

    Scoring guide for skin_impact_score (1-10):
      9-10: Superfoods for skin (salmon, avocado, berries, leafy greens, nuts, plain greek yogurt)
      7-8: Good for skin (eggs, sweet potato, olive oil, whole grains, legumes, oily fish)
      5-6: Neutral (chicken breast, white rice, pasta, bread, most fruits, lean meat)
      3-4: Mildly bad (fried foods, refined sugar, most packaged snacks, sweetened dairy)
      1-2: Bad for skin (candy, soda, alcohol, fast food, deep-fried foods, energy drinks)

    For skin_effects, use these metric_type values only: hydration, acne, dark_spots, redness, texture, pores, wrinkles
    For direction, use only: improved, worsened

    NUTRITION FIELD UNITS:
    - fiber: grams of dietary fiber
    - sugar: grams of total sugar (added + natural)
    - sodium: in GRAMS (not milligrams). E.g., 1500mg = 1.5g. A typical meal has 0.3-1.5g sodium.

    benefits (ALWAYS 2-4 items) — each must describe a CONCRETE property of THIS specific food and how it affects THIS user's skin. No generic "protein is good for you" statements. If the food scored below 5, these items should describe what is bad about it (e.g., "High added sugar (18g) can spike insulin and trigger breakouts").

    skin_effects (ALWAYS 2-4 items) — must line up with the score direction. Low score → mostly "worsened". High score → mostly "improved".

    ai_tip (REQUIRED) — one short sentence (max 22 words) that DIRECTLY references this food and is CONSISTENT with the score and benefits you just listed:
      • Score ≥ 7: celebrate the specific win (e.g. "Love the omega-3s from the salmon — great anti-inflammatory pick ✨").
      • Score 4-6: suggest ONE concrete upgrade or pairing (e.g. "Add a side of berries to offset the refined carbs 🫐").
      • Score ≤ 3: gently call out the downside and suggest a swap (e.g. "That sugar hit can trigger breakouts — try sparkling water next time 💫").
      DO NOT give generic advice like "eat more protein" or "drink water" that is unrelated to THIS food.

    Return ONLY valid JSON, no markdown.
    """

    private static func photoPrompt(userFoodName: String) -> String {
        """
        You are a nutrition and skin health expert. The user described their meal as "\(userFoodName)" and attached a photo.

        TRUST THE PHOTO, NOT THE LABEL. If what you see in the photo differs from the user's description, use the photo. If the photo is unclear, say so — do not invent details.

        Your job:
        1. Identify exactly what is on the plate, including visible sauces, oils, toppings, sides, and cooking method (grilled / fried / raw / etc.).
        2. Estimate the portion from visual cues (plate size, utensil, hand, packaging). State it implicitly through the calorie/macro numbers.
        3. Compute nutrition FOR THE VISIBLE PORTION, not for a standard recipe.
        4. Score the food for skin health and produce a tip that matches the score.

        Return ONLY valid JSON in this exact format (no markdown):
        {
          "food_name": "Concrete name of what is on the plate (e.g. 'Grilled salmon with quinoa and broccoli')",
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
        """
    }

    private static func barcodePrompt() -> String {
        """
        You are a nutrition and skin health expert. The user photographed a barcode on a packaged food product.

        Step 1: Read the barcode digits EXACTLY as they appear (8-13 digits). Do not guess missing digits.
        Step 2: Identify the product from the barcode, packaging colors, or visible branding/text. Include the brand name.
        Step 3: Provide nutrition values PER SINGLE SERVING for that specific product. Use the typical on-pack values for that SKU, not a generic category average.
        Step 4: Score the product for skin health and write a tip that matches.

        Return ONLY valid JSON in this exact format (no markdown):
        {
          "food_name": "Brand + product name (e.g. 'Coca-Cola Classic 330ml')",
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

        If the barcode is unreadable AND the packaging gives no product hint, set food_name to "Unclear packaged product", barcode to "", skin_impact_score to 5.0, and keep all nutrition values conservative and low-confidence.
        """
    }

    private static func labelPrompt() -> String {
        """
        You are a nutrition and skin health expert. The user photographed the nutrition facts label on a packaged food.

        STRICT LABEL-READING RULES:
        1. Transcribe the numbers literally from the label. Do NOT substitute category averages.
        2. Pay attention to the SERVING SIZE printed on the label. Return nutrition values PER ONE SERVING as shown.
        3. Convert units: sodium must be in GRAMS (divide mg by 1000). If the label shows "Sodium 450mg" return 0.45.
        4. If a number is unreadable or cut off, set it to 0 rather than inventing a value.
        5. Identify the product name from the label or surrounding packaging. If you can't read a brand name, use the product type (e.g. "Oat crackers").

        Return ONLY valid JSON in this exact format (no markdown):
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
