import Foundation

enum SkinMetricType: String, Codable, CaseIterable {
    case hydration
    case acne
    case texture
    case elasticity
    case darkSpots = "dark_spots"
    case redness
    case pores
    case wrinkles

    var displayName: String {
        switch self {
        case .hydration: return "Hydration"
        case .acne: return "Acne"
        case .texture: return "Texture"
        case .elasticity: return "Elasticity"
        case .darkSpots: return "Dark Spots"
        case .redness: return "Redness"
        case .pores: return "Pores"
        case .wrinkles: return "Wrinkles"
        }
    }

    var icon: String {
        switch self {
        case .hydration: return "💧"
        case .acne: return "✨"
        case .texture: return "🪞"
        case .elasticity: return "🤸"
        case .darkSpots: return "🔵"
        case .redness: return "🌡️"
        case .pores: return "🔬"
        case .wrinkles: return "🧴"
        }
    }
}

struct SkinMetric: Codable, Identifiable {
    let id: UUID
    let type: SkinMetricType
    let score: Double
    let label: String
    let severity: String
    let trend: String
    let description: String
    let createdAt: Date

    init(id: UUID = UUID(), type: SkinMetricType, score: Double, label: String = "", severity: String = "minimal", trend: String = "stable", description: String = "", createdAt: Date = Date()) {
        self.id = id
        self.type = type
        self.score = score
        self.label = label.isEmpty ? SkinMetric.labelForScore(score) : label
        self.severity = severity
        self.trend = trend
        self.description = description
        self.createdAt = createdAt
    }

    static func labelForScore(_ score: Double) -> String {
        switch score {
        case 70...100: return "Good"
        case 40..<70: return "Fair"
        default: return "Needs work"
        }
    }
}

struct SkinScan: Codable, Identifiable {
    let id: UUID
    let glowScore: Double
    let metrics: [SkinMetric]
    let imageURL: String?
    let aiInsight: String
    let overallMessage: String
    let createdAt: Date

    init(id: UUID = UUID(), glowScore: Double, metrics: [SkinMetric], imageURL: String? = nil, aiInsight: String = "", overallMessage: String = "", createdAt: Date = Date()) {
        self.id = id
        self.glowScore = glowScore
        self.metrics = metrics
        self.imageURL = imageURL
        self.aiInsight = aiInsight
        self.overallMessage = overallMessage
        self.createdAt = createdAt
    }
}

enum Trend: String, Codable {
    case improved
    case worsened
    case stable
}

struct SkinEffect: Codable, Identifiable {
    var id: String { "\(metricType.rawValue)-\(direction.rawValue)" }
    let metricType: SkinMetricType
    let direction: Trend
    let description: String
}

struct FoodScan: Codable, Identifiable, Equatable {
    static func == (lhs: FoodScan, rhs: FoodScan) -> Bool { lhs.id == rhs.id }

    let id: UUID
    let name: String
    let skinImpactScore: Double
    let calories: Int
    let protein: Double
    let fat: Double
    let carbs: Double
    let benefits: [String]
    let skinEffects: [SkinEffect]
    let photoData: Data?
    let aiTip: String?
    let createdAt: Date

    init(id: UUID = UUID(), name: String, skinImpactScore: Double, calories: Int, protein: Double, fat: Double, carbs: Double, benefits: [String] = [], skinEffects: [SkinEffect] = [], photoData: Data? = nil, aiTip: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.skinImpactScore = min(10, max(1, skinImpactScore))
        self.calories = calories
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.benefits = benefits
        self.skinEffects = skinEffects
        self.photoData = photoData
        self.aiTip = aiTip
        self.createdAt = createdAt
    }
}
