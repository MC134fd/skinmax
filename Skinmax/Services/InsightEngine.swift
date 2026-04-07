import Foundation

struct Insight: Identifiable {
    let id: UUID
    let emoji: String
    let text: String
    let type: InsightType
    let date: Date

    init(id: UUID = UUID(), emoji: String, text: String, type: InsightType, date: Date = Date()) {
        self.id = id
        self.emoji = emoji
        self.text = text
        self.type = type
        self.date = date
    }
}

enum InsightType: String, Codable {
    case correlation
    case tip
    case trend
    case streak
}

final class InsightEngine {
    func generateInsights(skinScans: [SkinScan], foodScans: [FoodScan]) -> [Insight] {
        var insights: [Insight] = []
        let calendar = Calendar.current

        let uniqueSkinDays = Set(skinScans.map { calendar.startOfDay(for: $0.createdAt) })
        let uniqueFoodDays = Set(foodScans.map { calendar.startOfDay(for: $0.createdAt) })
        let totalDays = uniqueSkinDays.union(uniqueFoodDays).count

        guard totalDays >= 3 else {
            return placeholderInsights(daysLogged: totalDays)
        }

        // Trend direction
        if skinScans.count >= 2 {
            let sorted = skinScans.sorted { $0.createdAt < $1.createdAt }
            let recentHalf = Array(sorted.suffix(sorted.count / 2))
            let olderHalf = Array(sorted.prefix(sorted.count / 2))
            let recentAvg = recentHalf.map(\.glowScore).reduce(0, +) / Double(recentHalf.count)
            let olderAvg = olderHalf.map(\.glowScore).reduce(0, +) / Double(olderHalf.count)
            let diff = recentAvg - olderAvg

            if abs(diff) > 2 {
                let direction = diff > 0 ? "improved" : "declined"
                let emoji = diff > 0 ? "📈" : "📉"
                insights.append(Insight(
                    emoji: emoji,
                    text: "Your skin score has \(direction) by \(Int(abs(diff))) points recently. \(diff > 0 ? "Keep it up!" : "Consider adjusting your diet and skincare routine.")",
                    type: .trend
                ))
            }
        }

        // High vs low food score correlation
        if foodScans.count >= 3 && skinScans.count >= 2 {
            let highFoodDays = foodScans.filter { $0.skinImpactScore >= 7 }
            let lowFoodDays = foodScans.filter { $0.skinImpactScore < 5 }

            if !highFoodDays.isEmpty && !lowFoodDays.isEmpty {
                let avgHighFood = highFoodDays.map(\.skinImpactScore).reduce(0, +) / Double(highFoodDays.count)
                let avgLowFood = lowFoodDays.map(\.skinImpactScore).reduce(0, +) / Double(lowFoodDays.count)

                if avgHighFood - avgLowFood > 2 {
                    insights.append(Insight(
                        emoji: "🥗",
                        text: "Your healthy meals (score 7+) average \(String(format: "%.1f", avgHighFood))/10 — significantly better than lower-scored meals (\(String(format: "%.1f", avgLowFood))/10). Eating well makes a visible difference!",
                        type: .correlation
                    ))
                }
            }
        }

        // Consistency
        let last7Days = Set((0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: Date()) }.map { calendar.startOfDay(for: $0) })
        let loggedDays = uniqueFoodDays.intersection(last7Days)
        if loggedDays.count >= 5 {
            insights.append(Insight(
                emoji: "⚡",
                text: "You've logged meals \(loggedDays.count) out of the last 7 days. Great consistency! Daily tracking helps spot patterns faster.",
                type: .streak
            ))
        } else if loggedDays.count < 3 {
            insights.append(Insight(
                emoji: "📝",
                text: "Try logging every meal for more accurate insights. You've logged \(loggedDays.count) of the last 7 days.",
                type: .tip
            ))
        }

        // General tips based on data
        if let latestScan = skinScans.sorted(by: { $0.createdAt > $1.createdAt }).first {
            let worstMetric = latestScan.metrics.min(by: { $0.score < $1.score })
            if let metric = worstMetric, metric.score < 60 {
                let tip = tipForMetric(metric.type)
                insights.append(Insight(
                    emoji: "💡",
                    text: "Your \(metric.type.displayName.lowercased()) score is \(Int(metric.score)). \(tip)",
                    type: .tip
                ))
            }
        }

        return insights
    }

    private func placeholderInsights(daysLogged: Int) -> [Insight] {
        var insights: [Insight] = []

        insights.append(Insight(
            emoji: "📊",
            text: "Log meals for \(3 - daysLogged) more day\(3 - daysLogged == 1 ? "" : "s") to start seeing skin-food correlations.",
            type: .tip
        ))

        insights.append(Insight(
            emoji: "🐟",
            text: "Tip: Foods rich in omega-3 (salmon, walnuts) are great for skin hydration and reducing redness.",
            type: .tip
        ))

        insights.append(Insight(
            emoji: "🍬",
            text: "Tip: Sugary foods can trigger inflammation and breakouts within 24-48 hours.",
            type: .tip
        ))

        return insights
    }

    private func tipForMetric(_ type: SkinMetricType) -> String {
        switch type {
        case .hydration: return "Try drinking more water and eating water-rich foods like cucumber."
        case .acne: return "Reducing dairy and sugar may help. Keep your pillowcase clean!"
        case .texture: return "Exfoliate gently 2-3x per week and use vitamin C serum."
        case .redness: return "Anti-inflammatory foods like salmon and avoiding spicy food can help."
        case .darkSpots: return "Vitamin C and sunscreen are your best friends for fading spots."
        case .pores: return "Niacinamide and double cleansing can minimize pore appearance."
        case .wrinkles: return "Retinol at night and staying hydrated help reduce fine lines."
        case .elasticity: return "Collagen-rich foods and facial massage can improve elasticity."
        }
    }
}
