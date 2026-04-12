import SwiftUI

struct HomeView: View {
    @Environment(DataStore.self) private var dataStore
    @Environment(AnalysisCoordinator.self) private var coordinator
    @State private var viewModel = HomeViewModel()
    @State private var selectedScanResult: SkinScan?
    @State private var selectedFoodResult: FoodScan?
    @State private var showFoodLog = false

    var onViewFaceResult: (SkinScan) -> Void = { _ in }
    var onViewFoodResult: (FoodScan) -> Void = { _ in }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                monthNavigation
                WeekDayStrip(
                    days: viewModel.weekDays,
                    selectedDate: viewModel.selectedDate,
                    daysWithData: viewModel.daysWithSkinData(),
                    onSelectDay: { date in
                        viewModel.selectDay(date)
                    }
                )

                // Analysis in progress card
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
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinator.isActive)
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
        .navigationDestination(isPresented: $showFoodLog) {
            FoodLogView()
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
                        .font(.system(size: 18))
                )
        }
        .padding(.top, 8)
    }

    // MARK: - Month Navigation

    private var monthNavigation: some View {
        HStack {
            Button { viewModel.previousMonth() } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(SkinmaxColors.mutedTan)
            }

            Spacer()

            Text(viewModel.monthTitle)
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            Spacer()

            Button { viewModel.nextMonth() } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(SkinmaxColors.mutedTan)
            }
        }
    }

    // MARK: - Glow Score Card

    private var glowScoreCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("GLOW SCORE")
                    .font(.custom("Nunito-Medium", size: 10))
                    .foregroundStyle(SkinmaxColors.mutedTan)
                    .tracking(2)

                if viewModel.hasData {
                    Text(String(format: "%.0f", viewModel.glowScore))
                        .font(.custom("Nunito-Bold", size: 42))
                        .foregroundStyle(SkinmaxColors.coral)

                    Text(viewModel.overallMessage)
                        .font(SkinmaxFonts.body())
                        .foregroundStyle(SkinmaxColors.warmGray)
                        .lineLimit(2)

                    Text(viewModel.trendPercentage)
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(viewModel.trendPositive ? SkinmaxColors.greenGood : SkinmaxColors.redAlert)
                } else {
                    Text("--")
                        .font(.custom("Nunito-Bold", size: 42))
                        .foregroundStyle(SkinmaxColors.mutedTan)

                    Text(viewModel.overallMessage)
                        .font(SkinmaxFonts.body())
                        .foregroundStyle(SkinmaxColors.warmGray)
                }
            }

            Spacer()

            ScoreRing(
                score: viewModel.glowScore,
                size: 90,
                lineWidth: 8,
                trackColor: SkinmaxColors.lightTan
            )
        }
        .padding(SkinmaxSpacing.cardPadding)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Metric Carousel

    private var metricCarousel: some View {
        Group {
            if viewModel.allMetrics.isEmpty {
                metricEmptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.allMetrics) { metric in
                            metricCarouselCard(metric)
                                .frame(width: 110)
                        }
                    }
                    .padding(.horizontal, 2)
                }
            }
        }
    }

    private func metricCarouselCard(_ metric: SkinMetric) -> some View {
        VStack(spacing: 8) {
            CircleMetricCard(
                label: metric.type.displayName,
                score: metric.score,
                icon: metric.type.icon,
                size: 70
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadiusSmall))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private var metricEmptyState: some View {
        VStack(spacing: 8) {
            Text("No metrics yet")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)
            Text("No scan for \(viewModel.selectedDayName)")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Recent Activity (Selected Date Face Scans)

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Recent activity")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            if viewModel.selectedDateScans.isEmpty {
                recentActivityEmptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.selectedDateScans.enumerated()), id: \.element.id) { index, scan in
                        Button {
                            selectedScanResult = scan
                        } label: {
                            ScanHistoryRow(scan: scan) {
                                selectedScanResult = scan
                            }
                        }
                        .buttonStyle(.plain)

                        if index < viewModel.selectedDateScans.count - 1 {
                            Divider()
                                .foregroundStyle(SkinmaxColors.lightTan)
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .background(SkinmaxColors.white)
                .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
        }
    }

    private var recentActivityEmptyState: some View {
        VStack(spacing: 8) {
            Text("\u{1F50D}")
                .font(.system(size: 28))
            Text("No scans on \(viewModel.selectedDayName)")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)
            Text("Take a face scan to see your results here")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
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
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
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
