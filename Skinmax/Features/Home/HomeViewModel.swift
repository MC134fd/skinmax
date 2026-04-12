import SwiftUI
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var dataStore: DataStore?
    var selectedDate: Date = .now
    var selectedMonth: Date = .now

    private let calendar = Calendar.current

    // MARK: - Day Picker

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

    func daysWithSkinData(in month: Date) -> Set<Int> {
        guard let monthInterval = calendar.dateInterval(of: .month, for: month),
              let dataStore else { return [] }
        let scans = dataStore.skinScans(last: 30)
        return Set(scans
            .filter { $0.createdAt >= monthInterval.start && $0.createdAt < monthInterval.end }
            .map { calendar.component(.day, from: $0.createdAt) })
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
        if newMonth > Date() { return }
        selectedMonth = newMonth
        if let firstDay = calendar.date(from: calendar.dateComponents([.year, .month], from: newMonth)) {
            selectedDate = min(firstDay, Date())
        }
    }

    func isSelected(_ date: Date) -> Bool {
        calendar.isDate(date, inSameDayAs: selectedDate)
    }

    func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    func isFuture(_ date: Date) -> Bool {
        date > Date()
    }

    func dayAbbreviation(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }

    func dayNumber(_ date: Date) -> String {
        "\(calendar.component(.day, from: date))"
    }

    // MARK: - Selected Day Data

    var skinScansForSelectedDate: [SkinScan] {
        dataStore?.skinScans(for: selectedDate) ?? []
    }

    var glowScoreForSelectedDate: Double? {
        skinScansForSelectedDate.first?.glowScore
    }

    var hasDataForSelectedDate: Bool {
        !skinScansForSelectedDate.isEmpty
    }

    // MARK: - Latest / Overall Data (used by analytics)

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

    var weeklyScores: [(day: String, score: Double)] {
        guard let dataStore else { return [] }
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
