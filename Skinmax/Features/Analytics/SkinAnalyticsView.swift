import SwiftUI
import Charts

struct SkinAnalyticsView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                if viewModel.hasData {
                    metricsGrid
                } else {
                    emptyState
                }

                if viewModel.weeklyScores.count >= 2 {
                    weeklyChart
                } else {
                    scanPromptCard
                }

                insightCard
            }
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.bottom, 100)
        }
        .onAppear {
            viewModel.dataStore = dataStore
        }
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

    // MARK: - Insight Card
    private var insightCard: some View {
        InsightCard(
            emoji: "\u{1F4A1}",
            title: "Today's Insight",
            message: viewModel.todayInsight
        )
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("No skin data yet")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)
            Text("Take your first face scan to see metrics here")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}
