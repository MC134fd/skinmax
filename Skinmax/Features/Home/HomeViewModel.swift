import SwiftUI
import Observation

// MARK: - Recent Activity Item (mixed skin + food)
enum RecentActivityItem: Identifiable {
    case skin(SkinScan)
    case food(FoodScan)

    var id: UUID {
        switch self {
        case .skin(let scan): return scan.id
        case .food(let scan): return scan.id
        }
    }

    var date: Date {
        switch self {
        case .skin(let scan): return scan.createdAt
        case .food(let scan): return scan.createdAt
        }
    }
}

@Observable
@MainActor
final class HomeViewModel {
    var dataStore: DataStore?
    var insightDismissed = false

    private let calendar = Calendar.current

    // MARK: - Glow Score (latest)

    var latestScan: SkinScan? {
        dataStore?.latestSkinScan()
    }

    var glowScore: Double {
        latestScan?.glowScore ?? 0
    }

    var hasData: Bool {
        latestScan != nil
    }

    var overallMessage: String {
        latestScan?.overallMessage ?? "Take your first scan!"
    }

    // MARK: - Top 4 Metrics

    var topMetrics: [SkinMetric] {
        guard let scan = latestScan else { return [] }
        let priority: [SkinMetricType] = [.hydration, .acne, .texture, .redness]
        var result: [SkinMetric] = []
        for type in priority {
            if let metric = scan.metrics.first(where: { $0.type == type }) {
                result.append(metric)
            }
        }
        if result.count < 4 {
            for metric in scan.metrics where !result.contains(where: { $0.type == metric.type }) {
                result.append(metric)
                if result.count >= 4 { break }
            }
        }
        return result
    }

    // MARK: - Trend

    var trendPercentage: String {
        guard let dataStore else { return "" }
        let scores = dataStore.dailySkinScores(last: 7)
        guard scores.count >= 2 else { return "First scan!" }
        let first = scores.first!.score
        let last = scores.last!.score
        let diff = last - first
        let pct = (diff / max(first, 1)) * 100
        if pct >= 0 {
            return "\u{2191} +\(Int(pct))% this week"
        } else {
            return "\u{2193} \(Int(pct))% this week"
        }
    }

    var trendPositive: Bool {
        guard let dataStore else { return true }
        let scores = dataStore.dailySkinScores(last: 7)
        guard scores.count >= 2 else { return true }
        return scores.last!.score >= scores.first!.score
    }

    // MARK: - Recent Activity (mixed skin + food, last 7 days)

    var recentActivity: [RecentActivityItem] {
        guard let dataStore else { return [] }
        let skinScans = dataStore.skinScans(last: 7)
        let foodScans = dataStore.foodScans(last: 7)
        var items: [RecentActivityItem] = []
        items.append(contentsOf: skinScans.map { .skin($0) })
        items.append(contentsOf: foodScans.map { .food($0) })
        items.sort { $0.date > $1.date }
        return items
    }

    // MARK: - Today Insight

    var todayInsight: String {
        guard let dataStore else {
            return "Scan your face and log meals daily to unlock personalized insights."
        }
        let engine = InsightEngine()
        let skinScans = dataStore.skinScans(last: 7)
        let foodScans = dataStore.foodScans(last: 7)
        let insights = engine.generateInsights(skinScans: skinScans, foodScans: foodScans)
        return insights.first?.text ?? "Scan your face and log meals daily to unlock personalized insights."
    }

    // MARK: - Food Score

    var foodScore: Double {
        dataStore?.averageFoodScore(for: Date()) ?? 0
    }

    var todayFoodCount: Int {
        dataStore?.todayFoodCount() ?? 0
    }

    // MARK: - Metric Helpers

    func metricEmoji(for type: SkinMetricType) -> String {
        switch type {
        case .hydration: return "\u{1F4A7}"
        case .acne: return "\u{1F534}"
        case .texture: return "\u{270B}"
        case .redness: return "\u{1F321}"
        default: return type.icon
        }
    }

    func metricValue(for metric: SkinMetric) -> String {
        if metric.type == .acne {
            return metric.score >= 70 ? "Low" : metric.score >= 40 ? "Mod" : "High"
        }
        return "\(Int(metric.score))%"
    }

    func metricColor(for metric: SkinMetric) -> Color {
        SkinmaxColors.trafficLight(for: metric.score)
    }

    // MARK: - Weekly Scores (kept for analytics reuse)

    var weeklyScores: [(day: String, score: Double)] {
        guard let dataStore else { return [] }
        let scores = dataStore.dailySkinScores(last: 7)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return scores.map { (formatter.string(from: $0.date), $0.score) }
    }
}
