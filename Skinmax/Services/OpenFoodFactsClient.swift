import Foundation
import os

/// Minimal data extracted from Open Food Facts for a single product lookup.
/// All nutrition numbers are per serving (preferred) or per 100g (fallback).
struct OpenFoodFactsProduct {
    let productName: String
    let brand: String?
    /// Nutrition values are left nil when OFF has no data — callers should fall
    /// back to GPT-4o estimates for missing fields.
    let calories: Int?
    let proteinGrams: Double?
    let fatGrams: Double?
    let carbsGrams: Double?
    let fiberGrams: Double?
    let sugarGrams: Double?
    /// Sodium reported in grams (OFF reports in grams already).
    let sodiumGrams: Double?
}

protocol OpenFoodFactsClientProtocol {
    func lookup(barcode: String) async -> OpenFoodFactsProduct?
}

/// Tiny client for the public Open Food Facts v2 API. No auth required.
/// Used to enrich barcode-mode scans after GPT-4o has extracted the code.
final class OpenFoodFactsClient: OpenFoodFactsClientProtocol {
    private let log = GlowbiteLog.foodAPI
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func lookup(barcode: String) async -> OpenFoodFactsProduct? {
        let cleaned = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty,
              let url = URL(string: "https://world.openfoodfacts.org/api/v2/product/\(cleaned).json") else {
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        // OFF asks apps to identify themselves in the User-Agent.
        request.setValue("Skinmax/1.0 (iOS)", forHTTPHeaderField: "User-Agent")

        do {
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                log.notice("OFF lookup non-200 for barcode=\(cleaned, privacy: .public)")
                return nil
            }
            return parse(data)
        } catch {
            log.notice("OFF lookup network error: \(error.localizedDescription)")
            return nil
        }
    }

    private func parse(_ data: Data) -> OpenFoodFactsProduct? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? Int,
              status == 1,
              let product = json["product"] as? [String: Any] else {
            return nil
        }

        let name = (product["product_name"] as? String)
            ?? (product["generic_name"] as? String)
            ?? "Packaged product"
        let brand = product["brands"] as? String

        // OFF nutrition keys end in `_serving` (per serving) or `_100g` (per 100g).
        // Prefer per-serving when available.
        let nutriments = product["nutriments"] as? [String: Any] ?? [:]

        func value(_ key: String) -> Double? {
            if let v = nutriments["\(key)_serving"] as? Double { return v }
            if let v = nutriments["\(key)_serving"] as? Int { return Double(v) }
            if let v = nutriments["\(key)_100g"] as? Double { return v }
            if let v = nutriments["\(key)_100g"] as? Int { return Double(v) }
            return nil
        }

        // OFF reports `energy-kcal` (kcal) or `energy` (kJ). Prefer kcal.
        let kcal = value("energy-kcal")

        return OpenFoodFactsProduct(
            productName: name,
            brand: brand?.isEmpty == true ? nil : brand,
            calories: kcal.map { Int($0.rounded()) },
            proteinGrams: value("proteins"),
            fatGrams: value("fat"),
            carbsGrams: value("carbohydrates"),
            fiberGrams: value("fiber"),
            sugarGrams: value("sugars"),
            sodiumGrams: value("sodium")
        )
    }
}
