import SwiftUI
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var dataStore: DataStore?
    var insightDismissed = false
    var selectedDate: Date = .now
    var selectedMonth: Date = .now

    private let calendar = Calendar.current

    // MARK: - Date Navigation

    var weekDays: [Date] {
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: selectedDate) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekInterval.start) }
    }

    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    var selectedDayName: String {
        if calendar.isDateInToday(selectedDate) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    func selectDay(_ date: Date) {
        guard date <= Date() else { return }
        selectedDate = date
        selectedMonth = date
    }

    func previousMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonth) else { return }
        selectedMonth = newMonth
        if let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: newMonth)) {
            selectedDate = firstDay
        }
    }

    func nextMonth() {
        guard let newMonth = calendar.date(byAdding: .month, value: 1, to: selectedMonth) else { return }
        let newComps = calendar.dateComponents([.year, .month], from: newMonth)
        let nowComps = calendar.dateComponents([.year, .month], from: Date())
        if (newComps.year!, newComps.month!) > (nowComps.year!, nowComps.month!) { return }
        selectedMonth = newMonth
        if let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: newMonth)) {
            selectedDate = min(firstDay, Date())
        }
    }

    func daysWithSkinData() -> Set<Int> {
        guard let dataStore else { return [] }
        var result = Set<Int>()
        for day in weekDays {
            if !dataStore.skinScans(for: day).isEmpty {
                result.insert(calendar.component(.day, from: day))
            }
        }
        return result
    }

    // MARK: - Selected Date Data

    var selectedDateScan: SkinScan? {
        dataStore?.skinScans(for: selectedDate).first
    }

    var selectedDateScans: [SkinScan] {
        dataStore?.skinScans(for: selectedDate) ?? []
    }

    // MARK: - Glow Score (selected date)

    var latestScan: SkinScan? {
        dataStore?.latestSkinScan()
    }

    var glowScore: Double {
        selectedDateScan?.glowScore ?? 0
    }

    var hasData: Bool {
        selectedDateScan != nil
    }

    var overallMessage: String {
        selectedDateScan?.overallMessage ?? "No scan for \(selectedDayName)"
    }

    // MARK: - All Metrics (for carousel, selected date)

    var allMetrics: [SkinMetric] {
        selectedDateScan?.metrics ?? []
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
