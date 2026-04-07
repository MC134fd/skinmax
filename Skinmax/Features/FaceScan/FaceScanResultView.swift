import SwiftUI

struct FaceScanResultView: View {
    let scan: SkinScan
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var animatedScore: Double = 0
    @State private var showMetrics = false
    @State private var selectedMetric: SkinMetric?
    @State private var showDetail = false
    @State private var saved = false
    @State private var showSaveToast = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    glowScoreCard
                    detailedAnalysisHeader
                    metricsGrid
                    aiInsightCard
                }
                .padding(.horizontal, SkinmaxSpacing.screenPadding)
                .padding(.bottom, 40)
            }
            .background(SkinmaxColors.creamBG.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(SkinmaxFonts.h3())
                        .foregroundStyle(SkinmaxColors.coral)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveScan()
                    } label: {
                        Text(saved ? "Saved" : "Save")
                            .font(SkinmaxFonts.h3())
                            .foregroundStyle(SkinmaxColors.darkBrown)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [SkinmaxColors.coral, SkinmaxColors.peachLight],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(saved)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
        }
        .overlay {
            if showSaveToast {
                VStack {
                    Spacer()
                    Text("Scan saved!")
                        .font(SkinmaxFonts.h3())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(SkinmaxColors.greenGood)
                        .clipShape(Capsule())
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .sheet(item: $selectedMetric) { metric in
            SkinDetailView(metric: metric)
        }
        .onAppear {
            animateScore()
            animateMetrics()
        }
    }

    // MARK: - Glow Score Card
    private var glowScoreCard: some View {
        VStack(spacing: 14) {
            // Circle ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 8)
                    .frame(width: 110, height: 110)

                Circle()
                    .trim(from: 0, to: animatedScore / 100.0)
                    .stroke(
                        SkinmaxColors.peachLight,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f", animatedScore))
                    .font(.custom("Nunito-Bold", size: 36))
                    .foregroundStyle(SkinmaxColors.peachLight)
            }

            // Overall message
            Text(scan.overallMessage)
                .font(SkinmaxFonts.h3())
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            // Trend
            Text("First scan!")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.greenGood)
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
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Detailed Analysis Header
    private var detailedAnalysisHeader: some View {
        HStack {
            Text("Detailed Analysis")
                .font(.custom("Nunito-Bold", size: 14))
                .foregroundStyle(SkinmaxColors.darkBrown)
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: SkinmaxSpacing.metricGridSpacing),
            GridItem(.flexible(), spacing: SkinmaxSpacing.metricGridSpacing),
        ], spacing: SkinmaxSpacing.metricGridSpacing) {
            ForEach(Array(scan.metrics.enumerated()), id: \.element.id) { index, metric in
                ResultMetricCard(metric: metric)
                    .opacity(showMetrics ? 1 : 0)
                    .offset(y: showMetrics ? 0 : 20)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.8)
                        .delay(Double(index) * 0.05),
                        value: showMetrics
                    )
                    .onTapGesture {
                        HapticManager.selection()
                        selectedMetric = metric
                    }
            }
        }
    }

    // MARK: - AI Insight Card
    private var aiInsightCard: some View {
        InsightCard(
            emoji: "💡",
            title: "AI Insight",
            message: scan.aiInsight
        )
    }

    // MARK: - Animations
    private func animateScore() {
        withAnimation(.easeOut(duration: 0.8)) {
            animatedScore = scan.glowScore
        }
    }

    private func animateMetrics() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            showMetrics = true
        }
    }

    // MARK: - Save
    private func saveScan() {
        dataStore.saveSkinScan(scan)
        HapticManager.notification(.success)
        saved = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showSaveToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showSaveToast = false
            }
        }
    }
}

// MARK: - Result Metric Card (tappable)
struct ResultMetricCard: View {
    let metric: SkinMetric
    @State private var animatedProgress: Double = 0

    private var color: Color { SkinmaxColors.trafficLight(for: metric.score) }

    var body: some View {
        VStack(spacing: 6) {
            // Mini circle ring
            ZStack {
                Circle()
                    .stroke(SkinmaxColors.lightTan, lineWidth: 5)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f", metric.score))
                    .font(.custom("Nunito-Bold", size: 16))
                    .foregroundStyle(SkinmaxColors.darkBrown)
            }

            // Metric name + emoji
            Text("\(metric.type.icon) \(metric.type.displayName)")
                .font(SkinmaxFonts.small())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .textCase(.uppercase)

            // Status label
            Text(SkinmaxColors.trafficLightLabel(for: metric.score))
                .font(SkinmaxFonts.caption())
                .foregroundStyle(color)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.2)) {
                animatedProgress = metric.score / 100.0
            }
        }
    }
}
