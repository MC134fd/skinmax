import SwiftUI

struct HomeView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator
    @State private var viewModel = HomeViewModel()
    @State private var selectedScanResult: SkinScan?
    @State private var selectedFoodResult: FoodScan?
    @State private var currentMetricPage: Int? = 0

    var onViewFaceResult: (SkinScan) -> Void = { _ in }
    var onViewFoodResult: (FoodScan) -> Void = { _ in }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                monthNavigation
                WeekDayStrip(
                    weeks: viewModel.allWeeks,
                    currentWeekIndex: viewModel.currentWeekIndex,
                    selectedDate: viewModel.selectedDate,
                    daysWithData: viewModel.daysWithSkinData(),
                    onSelectDay: { date in
                        viewModel.selectDay(date)
                    },
                    onPageChanged: { date in
                        viewModel.selectedMonth = date
                    }
                )

                if coordinator.isActive {
                    AnalysisHomeCard(
                        coordinator: coordinator,
                        onViewFaceResult: onViewFaceResult,
                        onViewFoodResult: onViewFoodResult,
                        onDismiss: {
                            coordinator.dismiss()
                        }
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .opacity
                    ))
                }

                glowScoreCard
                metricCarousel
                recentActivitySection
                insightCard
            }
            .padding(.horizontal, SkinmaxSpacing.screenPadding)
            .padding(.bottom, 100)
            .animation(.spring(response: 0.4, dampingFraction: 0.75), value: coordinator.isActive)
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
        .onAppear {
            viewModel.dataStore = dataStore
        }
        .fullScreenCover(item: $selectedScanResult) { scan in
            FaceScanResultView(scan: scan)
                .environment(dataStore)
        }
        .fullScreenCover(item: $selectedFoodResult) { scan in
            FoodScanResultView(scan: scan)
                .environment(dataStore)
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
                    Text("\u{1F469}")
                        .font(.gbTitleM)
                )
        }
        .padding(.top, 8)
    }

    // MARK: - Month Navigation

    private var monthNavigation: some View {
        HStack {
            Button { viewModel.previousMonth() } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(SkinmaxColors.lightTaupe)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(.gbTitleM)
                .foregroundStyle(SkinmaxColors.darkBrown)

            Spacer()

            Button { viewModel.nextMonth() } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(SkinmaxColors.lightTaupe)
            }
        }
    }

    // MARK: - Glow Score Card

    private var glowScoreCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("GLOW SCORE")
                    .font(.gbOverline)
                    .foregroundStyle(SkinmaxColors.mediumTaupe)
                    .tracking(2)

                if viewModel.hasData {
                    Text(String(format: "%.0f", viewModel.glowScore))
                        .font(.gbDisplayXL)
                        .foregroundStyle(SkinmaxColors.coral)

                    Text(viewModel.overallMessage)
                        .font(.gbBodyM)
                        .foregroundStyle(SkinmaxColors.warmBrown)
                        .lineLimit(2)

                    Text(viewModel.trendPercentage)
                        .font(.gbCaption)
                        .foregroundStyle(viewModel.trendPositive ? SkinmaxColors.greenGood : SkinmaxColors.redAlert)
                } else {
                    Text("--")
                        .font(.gbDisplayXL)
                        .foregroundStyle(SkinmaxColors.lightTaupe)

                    Text(viewModel.overallMessage)
                        .font(.gbBodyM)
                        .foregroundStyle(SkinmaxColors.warmBrown)
                }
            }

            Spacer()

            ScoreRing(
                score: viewModel.glowScore,
                size: 90,
                lineWidth: 12,
                trackColor: SkinmaxColors.softTan
            )
        }
        .padding(SkinmaxSpacing.cardPadding)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    // MARK: - Metric Carousel (3 per page, paged with dots)

    private var metricPages: [[SkinMetric]] {
        let metrics = viewModel.allMetrics
        return stride(from: 0, to: metrics.count, by: 3).map {
            Array(metrics[$0..<min($0 + 3, metrics.count)])
        }
    }

    private var metricCarousel: some View {
        Group {
            if viewModel.allMetrics.isEmpty {
                metricEmptyState
            } else {
                VStack(spacing: 10) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        LazyHStack(spacing: 0) {
                            ForEach(Array(metricPages.enumerated()), id: \.offset) { index, page in
                                HStack(spacing: 8) {
                                    ForEach(page) { metric in
                                        metricCarouselCard(metric)
                                    }
                                    if page.count < 3 {
                                        ForEach(0..<(3 - page.count), id: \.self) { _ in
                                            Color.clear.frame(maxWidth: .infinity)
                                        }
                                    }
                                }
                                .containerRelativeFrame(.horizontal)
                            }
                        }
                        .scrollTargetLayout()
                    }
                    .scrollTargetBehavior(.viewAligned)

                    if metricPages.count > 1 {
                        HStack(spacing: 6) {
                            ForEach(0..<metricPages.count, id: \.self) { index in
                                Circle()
                                    .fill(SkinmaxColors.softTan)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedDate) {
            currentMetricPage = 0
        }
    }

    private func metricCarouselCard(_ metric: SkinMetric) -> some View {
        VStack(spacing: 8) {
            CircleMetricCard(
                label: metric.type.displayName,
                score: metric.score,
                icon: metric.type.icon,
                size: 60
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 4)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    private var metricEmptyState: some View {
        VStack(spacing: 8) {
            Text("No metrics yet")
                .font(.gbTitleM)
                .foregroundStyle(SkinmaxColors.darkBrown)
            Text("No scan for \(viewModel.selectedDayName)")
                .font(.gbBodyM)
                .foregroundStyle(SkinmaxColors.lightTaupe)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SkinmaxSpacing.lg)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    // MARK: - Recent Activity (Face + Food, sorted by time)

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent activity")
                .font(.gbTitleM)
                .foregroundStyle(SkinmaxColors.darkBrown)

            let activity = viewModel.selectedDateActivity
            if activity.isEmpty {
                recentActivityEmptyState
            } else {
                VStack(spacing: 10) {
                    ForEach(activity) { item in
                        switch item {
                        case .face(let scan):
                            FaceActivityCard(scan: scan) {
                                selectedScanResult = scan
                            }
                        case .food(let foodScan):
                            FoodActivityCard(foodScan: foodScan) {
                                selectedFoodResult = foodScan
                            }
                        }
                    }
                }
            }
        }
    }

    private var recentActivityEmptyState: some View {
        VStack(spacing: 8) {
            Text("\u{1F50D}")
                .font(.gbDisplayM)
            Text("No activity on \(viewModel.selectedDayName)")
                .font(.gbTitleM)
                .foregroundStyle(SkinmaxColors.darkBrown)
            Text("Scan your face or log a meal to get started")
                .font(.gbBodyM)
                .foregroundStyle(SkinmaxColors.lightTaupe)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, SkinmaxSpacing.lg)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    // MARK: - Dismissible Insight Card

    @ViewBuilder
    private var insightCard: some View {
        if !viewModel.insightDismissed {
            DismissibleInsightCard(
                emoji: "\u{1F4A1}",
                title: "Today's Insight",
                message: viewModel.todayInsight,
                onDismiss: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        viewModel.insightDismissed = true
                    }
                }
            )
            .transition(.asymmetric(
                insertion: .identity,
                removal: .move(edge: .trailing).combined(with: .opacity)
            ))
        }
    }
}
