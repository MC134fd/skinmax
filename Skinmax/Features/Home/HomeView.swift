import SwiftUI
import Charts

struct HomeView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header

                if viewModel.hasData {
                    glowScoreCard
                    metricsGrid
                } else {
                    emptyScoreCard
                }

                if viewModel.weeklyScores.count >= 2 {
                    weeklyChart
                } else {
                    scanPromptCard
                }

                todayFoodSummary
                insightCard
            }
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.bottom, 100)
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
        .onAppear {
            viewModel.dataStore = dataStore
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text("skinmax")
                .h1Style()

            Spacer()

            Circle()
                .fill(SkinmaxColors.peachLight)
                .frame(width: 36, height: 36)
                .overlay(
                    Text("👩")
                        .font(.system(size: 18))
                )
        }
        .padding(.top, 8)
    }

    // MARK: - Glow Score Card
    private var glowScoreCard: some View {
        ScoreCard(
            score: viewModel.glowScore,
            label: "Glow Score",
            trend: viewModel.trendPercentage,
            trendPositive: !viewModel.trendPercentage.hasPrefix("-")
        )
    }

    // MARK: - Empty Score Card
    private var emptyScoreCard: some View {
        VStack(spacing: 12) {
            Text("--")
                .font(SkinmaxFonts.scoreDisplay())
                .foregroundStyle(SkinmaxColors.mutedTan)

            Text("GLOW SCORE")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .tracking(1.5)

            Text("Take your first scan")
                .font(SkinmaxFonts.small())
                .foregroundStyle(SkinmaxColors.coral)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, SkinmaxSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [SkinmaxColors.darkSurface, SkinmaxColors.darkMid],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
    }

    // MARK: - 2x2 Metrics Grid
    private var metricsGrid: some View {
        let metrics = viewModel.topMetrics
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: SkinmaxSpacing.metricGridSpacing),
            GridItem(.flexible(), spacing: SkinmaxSpacing.metricGridSpacing),
        ], spacing: SkinmaxSpacing.metricGridSpacing) {
            ForEach(metrics) { metric in
                MetricCard(
                    label: metric.type.displayName,
                    value: viewModel.metricValue(for: metric),
                    progress: metric.score / 100.0,
                    color: SkinmaxColors.trafficLight(for: metric.score)
                )
            }

            if viewModel.foodScore > 0 {
                MetricCard(
                    label: "Food Score",
                    value: String(format: "%.1f", viewModel.foodScore),
                    progress: viewModel.foodScore / 10.0,
                    color: SkinmaxColors.trafficLight(for: viewModel.foodScore * 10)
                )
            }
        }
    }

    // MARK: - Weekly Trend Chart
    private var weeklyChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("7-Day Trend")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            Chart {
                ForEach(Array(viewModel.weeklyScores.enumerated()), id: \.offset) { index, item in
                    LineMark(
                        x: .value("Day", item.day),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(SkinmaxColors.coral)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    AreaMark(
                        x: .value("Day", item.day),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [SkinmaxColors.coral.opacity(0.3), SkinmaxColors.coral.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Day", item.day),
                        y: .value("Score", item.score)
                    )
                    .foregroundStyle(SkinmaxColors.coral)
                    .symbolSize(index == viewModel.weeklyScores.count - 1 ? 40 : 20)
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
                    AxisValueLabel()
                        .font(SkinmaxFonts.small())
                        .foregroundStyle(SkinmaxColors.mutedTan)
                }
            }
            .frame(height: 180)
        }
        .padding(SkinmaxSpacing.cardPadding)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Scan Prompt
    private var scanPromptCard: some View {
        VStack(spacing: 8) {
            Text("Scan daily to see your trend")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.warmGray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Today Food Summary
    private var todayFoodSummary: some View {
        HStack {
            Text("🍽")
                .font(.system(size: 16))

            if viewModel.todayFoodCount > 0 {
                Text("Today: \(viewModel.todayFoodCount) meal\(viewModel.todayFoodCount == 1 ? "" : "s") logged")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.warmGray)

                if viewModel.foodScore > 0 {
                    Text("avg \(String(format: "%.1f", viewModel.foodScore))/10")
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(SkinmaxColors.trafficLight(for: viewModel.foodScore * 10))
                }
            } else {
                Text("No meals logged today")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(SkinmaxColors.mutedTan)
            }

            Spacer()
        }
        .padding(12)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Insight Card
    private var insightCard: some View {
        InsightCard(
            emoji: "💡",
            title: "Today's Insight",
            message: viewModel.todayInsight
        )
    }
}
