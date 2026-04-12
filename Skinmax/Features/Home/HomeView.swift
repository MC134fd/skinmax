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
            VStack(spacing: 0) {
                glowScoreBanner

                VStack(spacing: 18) {
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

                    metricStrip
                    recentActivitySection
                    insightCard
                }
                .padding(.horizontal, SkinmaxSpacing.screenPadding)
                .padding(.top, 18)
                .padding(.bottom, 100)
            }
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

    // MARK: - Glow Score Banner

    private var glowScoreBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Text("skinmax")
                    .h1Style()
                    .foregroundStyle(.white)

                Spacer()

                Circle()
                    .fill(SkinmaxColors.peachLight.opacity(0.3))
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text("\u{1F469}")
                            .font(.system(size: 18))
                    )
            }
            .padding(.top, 8)

            Text("GLOW SCORE")
                .font(.custom("Nunito-Medium", size: 10))
                .foregroundStyle(.white.opacity(0.5))
                .tracking(2)
                .padding(.top, 8)

            if viewModel.hasData {
                ScoreRing(score: viewModel.glowScore)

                Text(viewModel.overallMessage)
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)

                Text(viewModel.trendPercentage)
                    .font(SkinmaxFonts.caption())
                    .foregroundStyle(viewModel.trendPositive ? SkinmaxColors.greenGood : SkinmaxColors.redAlert)
            } else {
                ScoreRing(score: 0)

                Text("Take your first scan!")
                    .font(SkinmaxFonts.body())
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, SkinmaxSpacing.screenPadding)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(
                colors: [SkinmaxColors.darkSurface, SkinmaxColors.darkMid],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
        )
    }

    // MARK: - Horizontal Metric Strip

    private var metricStrip: some View {
        Group {
            if viewModel.topMetrics.isEmpty {
                // Empty state — 4 placeholder chips
                HStack(spacing: 8) {
                    ForEach(0..<4, id: \.self) { _ in
                        MetricChip(
                            emoji: "--",
                            value: "--",
                            label: "N/A",
                            color: SkinmaxColors.mutedTan
                        )
                    }
                }
            } else {
                HStack(spacing: 8) {
                    ForEach(viewModel.topMetrics) { metric in
                        MetricChip(
                            emoji: viewModel.metricEmoji(for: metric.type),
                            value: viewModel.metricValue(for: metric),
                            label: metric.type.displayName,
                            color: viewModel.metricColor(for: metric)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Activity")
                    .font(SkinmaxFonts.h3())
                    .foregroundStyle(SkinmaxColors.darkBrown)

                Spacer()

                Button {
                    showFoodLog = true
                } label: {
                    Text("See All")
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(SkinmaxColors.coral)
                }
            }

            if viewModel.recentActivity.isEmpty {
                recentActivityEmptyState
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(viewModel.recentActivity) { item in
                            recentActivityCard(item)
                        }
                    }
                }
            }
        }
    }

    private var recentActivityEmptyState: some View {
        VStack(spacing: 8) {
            Text("\u{1F4F7}")
                .font(.system(size: 28))
            Text("No activity yet")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)
            Text("Scan your face or log a meal to get started")
                .font(SkinmaxFonts.small())
                .foregroundStyle(SkinmaxColors.mutedTan)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    private func recentActivityCard(_ item: RecentActivityItem) -> some View {
        Button {
            switch item {
            case .skin(let scan):
                selectedScanResult = scan
            case .food(let scan):
                selectedFoodResult = scan
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                // Thumbnail area
                RoundedRectangle(cornerRadius: 12)
                    .fill(thumbnailBackground(for: item))
                    .frame(width: 120, height: 90)
                    .overlay(
                        Text(thumbnailEmoji(for: item))
                            .font(.system(size: 28))
                    )

                // Title
                Text(activityTitle(for: item))
                    .font(.custom("Nunito-SemiBold", size: 12))
                    .foregroundStyle(SkinmaxColors.darkBrown)
                    .lineLimit(1)

                // Score
                Text(activityScore(for: item))
                    .font(.custom("Nunito-Bold", size: 14))
                    .foregroundStyle(SkinmaxColors.coral)

                // Tags
                if let tags = activityTags(for: item), !tags.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.custom("Nunito-Medium", size: 8))
                                .foregroundStyle(SkinmaxColors.coral)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(SkinmaxColors.peachWash)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }

                // Time
                Text(item.date.formatted(date: .omitted, time: .shortened))
                    .font(SkinmaxFonts.small())
                    .foregroundStyle(SkinmaxColors.mutedTan)
            }
            .frame(width: 120)
        }
    }

    // MARK: - Activity Card Helpers

    private func thumbnailBackground(for item: RecentActivityItem) -> Color {
        switch item {
        case .skin: return SkinmaxColors.lightTan
        case .food: return SkinmaxColors.peachWash
        }
    }

    private func thumbnailEmoji(for item: RecentActivityItem) -> String {
        switch item {
        case .skin: return "\u{1F9D1}"
        case .food(let scan): return scan.name.isEmpty ? "\u{1F37D}" : "\u{1F37D}"
        }
    }

    private func activityTitle(for item: RecentActivityItem) -> String {
        switch item {
        case .skin: return "Face Scan"
        case .food(let scan): return scan.name
        }
    }

    private func activityScore(for item: RecentActivityItem) -> String {
        switch item {
        case .skin(let scan): return String(format: "%.0f", scan.glowScore)
        case .food(let scan): return String(format: "%.1f/10", scan.skinImpactScore)
        }
    }

    private func activityTags(for item: RecentActivityItem) -> [String]? {
        switch item {
        case .skin(let scan):
            return scan.metrics.prefix(2).map { "\($0.type.displayName) \($0.score >= 50 ? "\u{2191}" : "\u{2193}")" }
        case .food(let scan):
            return scan.skinEffects.prefix(2).map { "\($0.metricType.displayName) \($0.direction == .improved ? "\u{2191}" : "\u{2193}")" }
        }
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
