import Foundation

enum MockData {
    static let glowScore: Double = 78

    static let skinMetrics: [SkinMetric] = [
        SkinMetric(type: .hydration, score: 82),
        SkinMetric(type: .acne, score: 85, label: "Low"),
        SkinMetric(type: .texture, score: 68),
        SkinMetric(type: .elasticity, score: 74),
    ]

    static let weeklyScores: [(day: String, score: Double)] = [
        ("Mon", 72), ("Tue", 74), ("Wed", 71),
        ("Thu", 75), ("Fri", 78), ("Sat", 76), ("Sun", 78),
    ]

    static let todayInsight = "Your hydration levels have improved 12% this week. Keep drinking water and eating water-rich fruits — your skin is responding well!"

    static let latestScan = SkinScan(
        glowScore: 78,
        metrics: skinMetrics,
        aiInsight: "Your skin is looking great! Hydration is up and acne is well controlled. Keep up the current routine."
    )

    static let foodScans: [FoodScan] = [
        FoodScan(
            name: "Salmon Bowl",
            skinImpactScore: 8.5,
            calories: 480,
            protein: 35,
            fat: 18,
            carbs: 42,
            benefits: ["Rich in Omega-3 for skin elasticity", "High protein for collagen production"],
            skinEffects: [
                SkinEffect(metricType: .hydration, direction: .improved, description: "Healthy fats support moisture barrier"),
                SkinEffect(metricType: .redness, direction: .improved, description: "Omega-3s reduce inflammation"),
            ]
        ),
        FoodScan(
            name: "Green Smoothie",
            skinImpactScore: 9.0,
            calories: 220,
            protein: 8,
            fat: 5,
            carbs: 38,
            benefits: ["Vitamin C boosts collagen", "Antioxidants fight free radicals"],
            skinEffects: [
                SkinEffect(metricType: .texture, direction: .improved, description: "Vitamin C brightens skin"),
                SkinEffect(metricType: .darkSpots, direction: .improved, description: "Antioxidants fade dark spots"),
            ]
        ),
    ]

    static let foodScore: Double = 7.4
}
