import SwiftUI
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var dataStore: DataStore?
    var insightDismissed = false
    var selectedDate: Date = .now

    private let calendar = Calendar.current

    // MARK: - Date Navigation (Monday-start weeks)

    var allWeeks: [[Date]] {
        let today = calendar.startOfDay(for: Date())
        let weekday = calendar.component(.weekday, from: today)
        let daysSinceMonday = (weekday + 5) % 7
        guard let currentMonday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: today) else { return [] }

        var weeks: [[Date]] = []
        for weeksBack in (0..<5).reversed() {
            guard let monday = calendar.date(byAdding: .weekOfYear, value: -weeksBack, to: currentMonday) else { continue }
            let week = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: monday) }
            weeks.append(week)
        }
        return weeks
    }

    var currentWeekIndex: Int {
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: selectedDate)) else {
            return allWeeks.count - 1
        }
        return allWeeks.firstIndex { week in
            guard let weekMonday = week.first else { return false }
            return calendar.isDate(weekMonday, inSameDayAs: monday)
        } ?? allWeeks.count - 1
    }

    var selectedDayName: String {
        if calendar.isDateInToday(selectedDate) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    func selectDay(_ date: Date) {
        let today = calendar.startOfDay(for: Date())
        guard calendar.startOfDay(for: date) <= today else { return }
        selectedDate = date
    }

    func daysWithSkinData() -> Set<Int> {
        guard let dataStore else { return [] }
        let weekday = calendar.component(.weekday, from: selectedDate)
        let daysSinceMonday = (weekday + 5) % 7
        guard let monday = calendar.date(byAdding: .day, value: -daysSinceMonday, to: calendar.startOfDay(for: selectedDate)) else { return [] }
        var result = Set<Int>()
        for i in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: i, to: monday) else { continue }
            if !dataStore.skinScans(for: day).isEmpty {
                result.insert(calendar.component(.day, from: day))
            }
        }
        return result
    }

    // MARK: - Selected Date Data

    var selectedDateScan: SkinScan? {
        _ = dataStore?.dataVersion
        return dataStore?.skinScans(for: selectedDate).first
    }

    var selectedDateScans: [SkinScan] {
        _ = dataStore?.dataVersion
        return dataStore?.skinScans(for: selectedDate) ?? []
    }

    var selectedDateFoodScans: [FoodScan] {
        _ = dataStore?.dataVersion
        return dataStore?.foodScans(for: selectedDate) ?? []
    }

    var selectedDateActivity: [ActivityItem] {
        var seenFaceIDs = Set<UUID>()
        let uniqueScans = selectedDateScans.filter { seenFaceIDs.insert($0.id).inserted }
        var seenFoodIDs = Set<UUID>()
        let uniqueFoodScans = selectedDateFoodScans.filter { seenFoodIDs.insert($0.id).inserted }
        let faceItems = uniqueScans.map { ActivityItem.face($0) }
        let foodItems = uniqueFoodScans.map { ActivityItem.food($0) }
        return (faceItems + foodItems).sorted { $0.date > $1.date }
    }

    // MARK: - Glow Score (selected date)

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

    // MARK: - Calories (selected date food scans)

    let dailyCalorieGoal: Int = 2000

    var consumedCalories: Int {
        selectedDateFoodScans.reduce(0) { $0 + $1.calories }
    }

    var caloriesRemaining: Int {
        max(dailyCalorieGoal - consumedCalories, 0)
    }

    var calorieProgress: Double {
        guard dailyCalorieGoal > 0 else { return 0 }
        return Double(consumedCalories) / Double(dailyCalorieGoal)
    }

    // MARK: - Streak

    var streak: Int {
        dataStore?.calculateStreak() ?? 0
    }

    // MARK: - Glow Trend

    var glowTrendDiff: Int? {
        guard let dataStore else { return nil }
        let scores = dataStore.dailySkinScores(last: 7)
        guard scores.count >= 2 else { return nil }
        return Int(scores.last!.score - scores.first!.score)
    }

    // MARK: - Glow Score Bucket

    var glowScoreBucket: String {
        guard selectedDateScan != nil else { return "Scan to start" }
        let score = selectedDateScan?.glowScore ?? 0
        switch score {
        case 90...100: return "Glowing"
        case 75..<90: return "Great"
        case 60..<75: return "Good"
        case 40..<60: return "Fair"
        default: return "Low"
        }
    }

    // MARK: - Hydration (in-memory session state)
    // TODO: Persist to SwiftData and sync with Supabase.

    struct HydrationState {
        var consumedMl: Double = 0
        var goalMl: Double = 2_000

        var consumed: Double { consumedMl / 1_000 }
        var goal: Double { goalMl / 1_000 }
        var glasses: Int {
            let glassMl = 250.0
            return min(Int((consumedMl / glassMl).rounded(.down)), 8)
        }
    }

    var hydrationState = HydrationState()

    var hydration: (consumed: Double, goal: Double, glasses: Int) {
        (hydrationState.consumed, hydrationState.goal, hydrationState.glasses)
    }

    func addWater(ml: Double) {
        guard ml > 0 else { return }
        hydrationState.consumedMl += ml
    }

    // MARK: - Nutrient Traffic Light Zones

    enum NutrientZone {
        case tooLow, low, optimal, high, tooHigh

        var color: Color {
            switch self {
            case .tooLow, .tooHigh: return GlowbiteColors.redAlert
            case .low, .high: return GlowbiteColors.amberFair
            case .optimal: return GlowbiteColors.greenGood
            }
        }

        var lightColor: Color {
            switch self {
            case .tooLow, .tooHigh: return GlowbiteColors.redLight
            case .low, .high: return GlowbiteColors.amberLight
            case .optimal: return GlowbiteColors.greenLight
            }
        }
    }

    struct NutrientConfig {
        let label: String
        let unit: String
        let descriptor: String
        let signatureColor: Color
        let signatureLightColor: Color
        let target: Double
        let greenRange: ClosedRange<Double>
        let amberLowRange: ClosedRange<Double>?
        let amberHighRange: ClosedRange<Double>
        let maxDisplay: Double

        func zone(for value: Double) -> NutrientZone {
            if greenRange.contains(value) { return .optimal }
            if amberHighRange.contains(value) { return .high }
            if let amberLow = amberLowRange, amberLow.contains(value) { return .low }
            if value > amberHighRange.upperBound { return .tooHigh }
            return .tooLow
        }
    }

    static let nutrientConfigs: [NutrientConfig] = [
        NutrientConfig(label: "PROTEIN", unit: "g", descriptor: "Collagen fuel",
                       signatureColor: GlowbiteColors.nutrientProtein,
                       signatureLightColor: GlowbiteColors.nutrientProteinLight,
                       target: 50, greenRange: 40...80,
                       amberLowRange: 25...39, amberHighRange: 81...100, maxDisplay: 120),
        NutrientConfig(label: "CARBS", unit: "g", descriptor: "Energy source",
                       signatureColor: GlowbiteColors.nutrientCarbs,
                       signatureLightColor: GlowbiteColors.nutrientCarbsLight,
                       target: 250, greenRange: 150...300,
                       amberLowRange: 100...149, amberHighRange: 301...375, maxDisplay: 400),
        NutrientConfig(label: "FAT", unit: "g", descriptor: "Skin barrier",
                       signatureColor: GlowbiteColors.nutrientFat,
                       signatureLightColor: GlowbiteColors.nutrientFatLight,
                       target: 65, greenRange: 44...78,
                       amberLowRange: 25...43, amberHighRange: 79...100, maxDisplay: 120),
        NutrientConfig(label: "FIBER", unit: "g", descriptor: "Gut-skin axis",
                       signatureColor: GlowbiteColors.nutrientFiber,
                       signatureLightColor: GlowbiteColors.nutrientFiberLight,
                       target: 28, greenRange: 20...35,
                       amberLowRange: 10...19, amberHighRange: 36...45, maxDisplay: 50),
        NutrientConfig(label: "SUGAR", unit: "g", descriptor: "Breakout flag",
                       signatureColor: GlowbiteColors.nutrientSugar,
                       signatureLightColor: GlowbiteColors.nutrientSugarLight,
                       target: 25, greenRange: 0...25,
                       amberLowRange: nil, amberHighRange: 26...40, maxDisplay: 60),
        NutrientConfig(label: "SODIUM", unit: "g", descriptor: "Puffiness risk",
                       signatureColor: GlowbiteColors.nutrientSodium,
                       signatureLightColor: GlowbiteColors.nutrientSodiumLight,
                       target: 1.5, greenRange: 0.8...1.5,
                       amberLowRange: 0.4...0.79, amberHighRange: 1.51...2.3, maxDisplay: 3.0),
    ]

    struct NutrientDisplayData: Identifiable {
        let id = UUID()
        let config: NutrientConfig
        let currentValue: Double
        let zone: NutrientZone
        let progress: Double
        let remainingWithUnit: String  // "50g", "0.6g"
        let statusWord: String         // "left" or "over"
        let isOver: Bool
        var signatureColor: Color { config.signatureColor }
        var signatureLightColor: Color { config.signatureLightColor }
        var barColor: Color { config.signatureColor }
    }

    var nutrientPages: [[NutrientDisplayData]] {
        let scans = selectedDateFoodScans

        let totals: [Double] = [
            scans.reduce(0) { $0 + $1.protein },
            scans.reduce(0) { $0 + $1.carbs },
            scans.reduce(0) { $0 + $1.fat },
            scans.reduce(0) { $0 + $1.fiber },
            scans.reduce(0) { $0 + $1.sugar },
            scans.reduce(0) { $0 + $1.sodium },
        ]

        let configs = Self.nutrientConfigs
        let displayData: [NutrientDisplayData] = zip(configs, totals).map { config, value in
            let diff = config.target - value
            let isOver = diff < 0
            let absRemaining = abs(diff)
            let numStr: String
            if config.label == "SODIUM" {
                numStr = String(format: "%.1f", absRemaining)
            } else {
                numStr = "\(Int(absRemaining))"
            }
            return NutrientDisplayData(
                config: config,
                currentValue: value,
                zone: config.zone(for: value),
                progress: min(value / config.maxDisplay, 1.0),
                remainingWithUnit: "\(numStr)\(config.unit)",
                statusWord: isOver ? "over" : "left",
                isOver: isOver
            )
        }

        return [
            Array(displayData[0..<3]),
            Array(displayData[3..<6]),
        ]
    }

    // MARK: - Food Score

    var foodScore: Double {
        dataStore?.averageFoodScore(for: selectedDate) ?? 0
    }

    var selectedDateFoodCount: Int {
        selectedDateFoodScans.count
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
        GlowbiteColors.trafficLight(for: metric.score)
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
