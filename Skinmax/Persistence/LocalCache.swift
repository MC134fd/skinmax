import Foundation
import SwiftData

@Model
class CachedSkinScan {
    var id: UUID
    var date: Date
    var glowScore: Int
    var photoData: Data?
    var aiInsight: String?
    var overallMessage: String?
    var metricsJSON: Data

    init(from scan: SkinScan) {
        self.id = scan.id
        self.date = scan.createdAt
        self.glowScore = Int(scan.glowScore)
        self.aiInsight = scan.aiInsight
        self.overallMessage = scan.overallMessage
        self.metricsJSON = (try? JSONEncoder().encode(scan.metrics)) ?? Data()
    }

    func toSkinScan() -> SkinScan {
        let metrics = (try? JSONDecoder().decode([SkinMetric].self, from: metricsJSON)) ?? []
        return SkinScan(
            id: id,
            glowScore: Double(glowScore),
            metrics: metrics,
            aiInsight: aiInsight ?? "",
            overallMessage: overallMessage ?? "",
            createdAt: date
        )
    }
}

@Model
class CachedFoodScan {
    var id: UUID
    var date: Date
    var foodName: String
    var skinImpactScore: Double
    var calories: Int
    var protein: Double
    var fat: Double
    var carbs: Double
    var fiber: Double = 0
    var sugar: Double = 0
    var sodium: Double = 0
    var benefitsJSON: Data
    var skinEffectsJSON: Data
    var aiTip: String?
    var photoData: Data?

    init(from scan: FoodScan) {
        self.id = scan.id
        self.date = scan.createdAt
        self.foodName = scan.name
        self.skinImpactScore = scan.skinImpactScore
        self.calories = scan.calories
        self.protein = scan.protein
        self.fat = scan.fat
        self.carbs = scan.carbs
        self.fiber = scan.fiber
        self.sugar = scan.sugar
        self.sodium = scan.sodium
        self.benefitsJSON = (try? JSONEncoder().encode(scan.benefits)) ?? Data()
        self.skinEffectsJSON = (try? JSONEncoder().encode(scan.skinEffects)) ?? Data()
        self.aiTip = scan.aiTip
        self.photoData = scan.photoData
    }

    func toFoodScan() -> FoodScan {
        let benefits = (try? JSONDecoder().decode([String].self, from: benefitsJSON)) ?? []
        let skinEffects = (try? JSONDecoder().decode([SkinEffect].self, from: skinEffectsJSON)) ?? []
        return FoodScan(
            id: id,
            name: foodName,
            skinImpactScore: skinImpactScore,
            calories: calories,
            protein: protein,
            fat: fat,
            carbs: carbs,
            fiber: fiber,
            sugar: sugar,
            sodium: sodium,
            benefits: benefits,
            skinEffects: skinEffects,
            photoData: photoData,
            aiTip: aiTip,
            createdAt: date
        )
    }
}
