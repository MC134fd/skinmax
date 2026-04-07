import SwiftUI
import Charts

struct TrendsView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var timeRange: TimeRange = .week

    enum TimeRange: String, CaseIterable {
        case week = "7 Days"
        case month = "30 Days"

        var days: Int {
            switch self {
            case .week: return 7
            case .month: return 30
            }
        }
    }

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

    private var insights: [Insight] {
        let engine = InsightEngine()
        let skinScans = dataStore.skinScans(last: timeRange.days)
        let foodScans = dataStore.foodScans(last: timeRange.days)
        return engine.generateInsights(skinScans: skinScans, foodScans: foodScans)
    }

    private var hasEnoughData: Bool {
        skinData.count + foodData.count >= 3
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Trends")
                    .font(SkinmaxFonts.h2())
                    .foregroundStyle(SkinmaxColors.darkBrown)
                    .padding(.top, 12)

                timeRangePicker

                if hasEnoughData {
                    chartCard
                    scoreSummary
                }

                insightsSection

                if !hasEnoughData {
                    emptyState
                }
            }
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.bottom, 100)
        }
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
                        .font(.custom("Nunito-SemiBold", size: 12))
                        .foregroundStyle(timeRange == range ? .white : SkinmaxColors.darkBrown)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            timeRange == range ? SkinmaxColors.coral : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
        .padding(3)
        .background(SkinmaxColors.peachWash)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Chart Card
    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Chart {
                ForEach(Array(skinData.enumerated()), id: \.offset) { _, point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Score", point.score)
                    )
                    .foregroundStyle(SkinmaxColors.coral)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
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
                        y: .value("Score", point.avgScore * 10) // Normalize to 0-100
                    )
                    .foregroundStyle(SkinmaxColors.greenGood)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
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
            .frame(height: 220)

            // Legend
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Circle().fill(SkinmaxColors.coral).frame(width: 6, height: 6)
                    Text("Skin Score").font(SkinmaxFonts.caption()).foregroundStyle(SkinmaxColors.warmGray)
                }
                HStack(spacing: 4) {
                    Circle().fill(SkinmaxColors.greenGood).frame(width: 6, height: 6)
                    Text("Food Avg (×10)").font(SkinmaxFonts.caption()).foregroundStyle(SkinmaxColors.warmGray)
                }
            }
        }
        .padding(SkinmaxSpacing.cardPadding)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Score Summary
    private var scoreSummary: some View {
        HStack(spacing: 12) {
            // Skin score card
            VStack(spacing: 4) {
                Text("AVG SKIN SCORE")
                    .font(SkinmaxFonts.small())
                    .foregroundStyle(SkinmaxColors.mutedTan)
                    .textCase(.uppercase)

                if let avg = avgSkinScore {
                    Text(String(format: "%.0f", avg))
                        .font(.custom("Nunito-Bold", size: 22))
                        .foregroundStyle(SkinmaxColors.trafficLight(for: avg))
                } else {
                    Text("--")
                        .font(.custom("Nunito-Bold", size: 22))
                        .foregroundStyle(SkinmaxColors.mutedTan)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(SkinmaxColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)

            // Food score card
            VStack(spacing: 4) {
                Text("AVG FOOD SCORE")
                    .font(SkinmaxFonts.small())
                    .foregroundStyle(SkinmaxColors.mutedTan)
                    .textCase(.uppercase)

                if let avg = avgFoodScore {
                    HStack(spacing: 2) {
                        Text(String(format: "%.1f", avg))
                            .font(.custom("Nunito-Bold", size: 22))
                            .foregroundStyle(SkinmaxColors.trafficLight(for: avg * 10))
                        Text("/10")
                            .font(SkinmaxFonts.caption())
                            .foregroundStyle(SkinmaxColors.mutedTan)
                    }
                } else {
                    Text("--")
                        .font(.custom("Nunito-Bold", size: 22))
                        .foregroundStyle(SkinmaxColors.mutedTan)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(SkinmaxColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }

    // MARK: - Insights
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Insights")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            ForEach(insights) { insight in
                InsightCard(
                    emoji: insight.emoji,
                    title: "",
                    message: insight.text
                )
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("📊")
                .font(.system(size: 40))

            Text("Keep logging!")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            let dataPoints = skinData.count + foodData.count
            Text("We need at least 3 days of data to show trends.\n\(dataPoints) of 3 days logged.")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .multilineTextAlignment(.center)

            // Mini progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SkinmaxColors.lightTan)
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SkinmaxColors.coral)
                        .frame(width: geo.size.width * min(Double(dataPoints) / 3.0, 1.0), height: 6)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 60)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}
