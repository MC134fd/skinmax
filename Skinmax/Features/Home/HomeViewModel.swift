import SwiftUI
import Observation

@Observable
final class HomeViewModel {
    var dataStore: DataStore?

    var latestScan: SkinScan? {
        dataStore?.latestSkinScan()
    }

    var glowScore: Double {
        latestScan?.glowScore ?? 0
    }

    var hasData: Bool {
        latestScan != nil
    }

    var topMetrics: [SkinMetric] {
        guard let scan = latestScan else { return [] }
        // Pick 4 key metrics: hydration, acne, texture, redness (or whatever is available)
        let priority: [SkinMetricType] = [.hydration, .acne, .texture, .redness]
        var result: [SkinMetric] = []
        for type in priority {
            if let metric = scan.metrics.first(where: { $0.type == type }) {
                result.append(metric)
            }
        }
        // Fill remaining slots from other metrics
        if result.count < 4 {
            for metric in scan.metrics where !result.contains(where: { $0.type == metric.type }) {
                result.append(metric)
                if result.count >= 4 { break }
            }
        }
        return result
    }

    var weeklyScores: [(day: String, score: Double)] {
        guard let dataStore else { return [] }
        let     calendar = Calendar.current
        let scores = dataStore.dailySkinScores(last: 7)
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return scores.map { (formatter.string(from: $0.date), $0.score) }
    }

    var trendPercentage: String {
        guard let dataStore else { return "" }
        let scores = dataStore.dailySkinScores(last: 7)
        guard scores.count >= 2 else { return "First scan!" }
        let first = scores.first!.score
        let last = scores.last!.score
        let diff = last - first
        let pct = (diff / first) * 100
        if pct >= 0 {
            return "+\(Int(pct))% this week"
        } else {
            return "\(Int(pct))% this week"
        }
    }

    var foodScore: Double {
        dataStore?.averageFoodScore(for: Date()) ?? 0
    }

    var todayFoodCount: Int {
        dataStore?.todayFoodCount() ?? 0
    }

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

    func metricColor(for metric: SkinMetric) -> Color {
        switch metric.type {
        case .hydration: return SkinmaxColors.hydrationBlue
        default: return SkinmaxColors.trafficLight(for: metric.score)
        }
    }

    func metricValue(for metric: SkinMetric) -> String {
        if metric.type == .acne {
            return metric.score >= 70 ? "Low" : metric.score >= 40 ? "Moderate" : "High"
        }
        return "\(Int(metric.score))%"
    }
}
