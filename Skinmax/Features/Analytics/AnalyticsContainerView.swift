import SwiftUI
import Charts

struct AnalyticsContainerView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var timeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "7D"
        case month = "30D"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }

    // MARK: - Data

    private var skinData: [(date: Date, score: Double)] {
        dataStore.dailySkinScores(last: timeRange.days)
    }

    private var foodData: [(date: Date, avgScore: Double)] {
        dataStore.dailyFoodScores(last: timeRange.days)
    }

    private var avgSkinScore: Double? {
        guard !skinData.isEmpty else { return nil }
        return skinData.map(\.score).reduce(0, +) / Double(skinData.count)
    }

    private var avgFoodScore: Double? {
        guard !foodData.isEmpty else { return nil }
        return foodData.map(\.avgScore).reduce(0, +) / Double(foodData.count)
    }

    private var skinScoreChange: Double? {
        guard skinData.count >= 2, let first = skinData.first?.score, first > 0 else { return nil }
        let last = skinData.last!.score
        return ((last - first) / first) * 100
    }

    private var foodScoreChange: Double? {
        guard foodData.count >= 2, let first = foodData.first?.avgScore, first > 0 else { return nil }
        let last = foodData.last!.avgScore
        return ((last - first) / first) * 100
    }

    private var insights: [Insight] {
        let engine = InsightEngine()
        let skinScans = dataStore.skinScans(last: timeRange.days)
        let foodScans = dataStore.foodScans(last: timeRange.days)
        return engine.generateInsights(skinScans: skinScans, foodScans: foodScans)
    }

    private var hasEnoughData: Bool {
        skinData.count + foodData.count >= 2
    }

    // MARK: - Weekly Summary Data

    private var bestDay: (date: Date, score: Double)? {
        skinData.max(by: { $0.score < $1.score })
    }

    private var worstDay: (date: Date, score: Double)? {
        skinData.min(by: { $0.score < $1.score })
    }

    private var topFood: FoodScan? {
        dataStore.foodScans(last: timeRange.days).max(by: { $0.skinImpactScore < $1.skinImpactScore })
    }

    private var scanStreak: Int {
        dataStore.calculateStreak()
    }

    private var foodLogStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var checkDate = Date()
        for _ in 0..<365 {
            let scans = dataStore.foodScans(for: checkDate)
            if !scans.isEmpty {
                streak += 1
            } else {
                break
            }
            guard let prev = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prev
        }
        return streak
    }

    // MARK: - Body

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text("Analytics")
                    .font(SkinmaxFonts.h2())
                    .foregroundStyle(SkinmaxColors.darkBrown)
                    .padding(.top, 12)

                if hasEnoughData {
                    trendChartCard
                    scoreSummaryRow
                } else {
                    emptyChartState
                }

                aiInsightsSection
                weeklySummarySection
            }
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.bottom, 100)
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
    }

    // MARK: - Trend Chart Card

    private var trendChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Skin vs. Food Trends")
                    .font(SkinmaxFonts.h3())
                    .foregroundStyle(SkinmaxColors.darkBrown)

                Spacer()

                timeRangePicker
            }

            Chart {
                ForEach(Array(skinData.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(SkinmaxColors.coral)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(SkinmaxColors.coral)
                    .symbolSize(30)
                }

                ForEach(Array(foodData.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.avgScore * 10)
                    )
                    .foregroundStyle(SkinmaxColors.greenGood)
                    .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.avgScore * 10)
                    )
                    .foregroundStyle(SkinmaxColors.greenGood)
                    .symbolSize(30)
                }
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisValueLabel()
                        .font(SkinmaxFonts.small())
                        .foregroundStyle(SkinmaxColors.mutedTan)
                    AxisGridLine()
                        .foregroundStyle(SkinmaxColors.lightTan)
                }
            }
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                        .font(SkinmaxFonts.small())
                        .foregroundStyle(SkinmaxColors.mutedTan)
                }
            }
            .frame(height: 200)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(SkinmaxColors.coral).frame(width: 6, height: 6)
                    Text("Skin Score")
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(SkinmaxColors.warmGray)
                }
                HStack(spacing: 4) {
                    Circle().fill(SkinmaxColors.greenGood).frame(width: 6, height: 6)
                    Text("Food Avg")
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(SkinmaxColors.warmGray)
                }
            }
        }
        .padding(SkinmaxSpacing.cardPadding)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        timeRange = range
                    }
                } label: {
                    Text(range.rawValue)
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(timeRange == range ? SkinmaxColors.coral : SkinmaxColors.mutedTan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            timeRange == range ? SkinmaxColors.peachWash : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    // MARK: - Score Summary Row

    private var scoreSummaryRow: some View {
        HStack(spacing: 12) {
            scoreSummaryCard(
                label: "AVG SKIN SCORE",
                value: avgSkinScore.map { String(format: "%.0f", $0) },
                color: avgSkinScore.map { SkinmaxColors.trafficLight(for: $0) },
                change: skinScoreChange,
                suffix: nil
            )

            scoreSummaryCard(
                label: "AVG FOOD SCORE",
                value: avgFoodScore.map { String(format: "%.1f", $0) },
                color: avgFoodScore.map { SkinmaxColors.trafficLight(for: $0 * 10) },
                change: foodScoreChange,
                suffix: "/10"
            )
        }
    }

    private func scoreSummaryCard(label: String, value: String?, color: Color?, change: Double?, suffix: String?) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(SkinmaxFonts.small())
                .foregroundStyle(SkinmaxColors.mutedTan)

            HStack(spacing: 2) {
                Text(value ?? "--")
                    .font(.custom("Nunito-Bold", size: 22))
                    .foregroundStyle(color ?? SkinmaxColors.mutedTan)

                if let suffix {
                    Text(suffix)
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(SkinmaxColors.mutedTan)
                }
            }

            if let change {
                let positive = change >= 0
                Text("\(positive ? "\u{2191}" : "\u{2193}") \(positive ? "+" : "")\(String(format: "%.1f", change))%")
                    .font(SkinmaxFonts.caption())
                    .foregroundStyle(positive ? SkinmaxColors.greenGood : SkinmaxColors.redAlert)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - AI Insights Section

    private var aiInsightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI Insights")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            if insights.isEmpty {
                Text("Log more data to unlock AI insights.")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.mutedTan)
                    .padding(.vertical, 12)
            } else {
                ForEach(insights) { insight in
                    HStack(alignment: .top, spacing: 10) {
                        Text(insight.emoji)
                            .font(.system(size: 16))

                        Text(insight.text)
                            .font(SkinmaxFonts.body())
                            .foregroundStyle(SkinmaxColors.darkBrown)
                            .lineSpacing(2)

                        Spacer(minLength: 0)

                        Text("— AI")
                            .font(SkinmaxFonts.small())
                            .foregroundStyle(SkinmaxColors.mutedTan)
                    }
                    .padding(14)
                    .background(SkinmaxColors.peachWash)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
            }
        }
    }

    // MARK: - Weekly Summary Section

    private var weeklySummarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Summary")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            VStack(spacing: 0) {
                if let best = bestDay {
                    summaryRow(
                        icon: "\u{1F3C6}",
                        label: "Best Day",
                        value: "\(Int(best.score)) — \(best.date.formatted(date: .abbreviated, time: .omitted))",
                        color: SkinmaxColors.greenGood,
                        showDivider: true
                    )
                }

                if let worst = worstDay {
                    summaryRow(
                        icon: "\u{1F4C9}",
                        label: "Worst Day",
                        value: "\(Int(worst.score)) — \(worst.date.formatted(date: .abbreviated, time: .omitted))",
                        color: SkinmaxColors.redAlert,
                        showDivider: true
                    )
                }

                if let food = topFood {
                    summaryRow(
                        icon: "\u{1F947}",
                        label: "Top Food",
                        value: "\(food.name) (\(String(format: "%.1f", food.skinImpactScore))/10)",
                        color: SkinmaxColors.greenGood,
                        showDivider: true
                    )
                }

                summaryRow(
                    icon: "\u{1F525}",
                    label: "Scan Streak",
                    value: "\(scanStreak) days",
                    color: SkinmaxColors.coral,
                    showDivider: true
                )

                summaryRow(
                    icon: "\u{1F37D}",
                    label: "Log Streak",
                    value: "\(foodLogStreak) days",
                    color: SkinmaxColors.coral,
                    showDivider: false
                )
            }
            .background(SkinmaxColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }

    private func summaryRow(icon: String, label: String, value: String, color: Color, showDivider: Bool) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(icon)
                    .font(.system(size: 14))

                Text(label)
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.warmGray)

                Spacer()

                Text(value)
                    .font(.custom("Nunito-SemiBold", size: 13))
                    .foregroundStyle(color)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            if showDivider {
                Divider()
                    .foregroundStyle(SkinmaxColors.lightTan)
                    .padding(.horizontal, 14)
            }
        }
    }

    // MARK: - Empty Chart State

    private var emptyChartState: some View {
        VStack(spacing: 12) {
            Text("\u{1F4CA}")
                .font(.system(size: 40))

            Text("Keep logging!")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            let dataPoints = skinData.count + foodData.count
            Text("We need at least 2 days of data to show trends.\n\(dataPoints) of 2 days logged.")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .multilineTextAlignment(.center)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SkinmaxColors.lightTan)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SkinmaxColors.coral)
                        .frame(width: geo.size.width * min(Double(dataPoints) / 2.0, 1.0), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}
