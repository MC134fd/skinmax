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
                .padding(.horizontal, GlowbiteSpacing.screenPadding)
                .padding(.bottom, 40)
            }
            .background(GlowbiteColors.creamBG.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.coral)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveScan()
                    } label: {
                        Text(saved ? "Saved" : "Save")
                            .font(.gbBodyM)
                            .foregroundStyle(GlowbiteColors.darkBrown)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(
                                LinearGradient(
                                    colors: [GlowbiteColors.coral, GlowbiteColors.peachLight],
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
                        .font(.gbBodyM)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(GlowbiteColors.greenGood)
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
                        GlowbiteColors.peachLight,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f", animatedScore))
                    .font(.gbDisplayL)
                    .tracking(-1.0)
                    .foregroundStyle(GlowbiteColors.peachLight)
            }

            // Overall message
            Text(scan.overallMessage)
                .font(.gbBodyM)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)

            // Trend
            Text("First scan!")
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.greenGood)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, GlowbiteSpacing.cardPadding)
        .background(
            LinearGradient(
                colors: [GlowbiteColors.darkBrown, GlowbiteColors.warmBrown],
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
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.darkBrown)
            Spacer()
        }
        .padding(.top, 4)
    }

    // MARK: - Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: GlowbiteSpacing.metricGridSpacing),
            GridItem(.flexible(), spacing: GlowbiteSpacing.metricGridSpacing),
        ], spacing: GlowbiteSpacing.metricGridSpacing) {
            ForEach(Array(scan.metrics.enumerated()), id: \.element.id) { index, metric in
                ResultMetricCard(metric: metric)
                    .opacity(showMetrics ? 1 : 0)
                    .offset(y: showMetrics ? 0 : 20)
                    .animation(
                        .spring(response: 0.4, dampingFraction: 0.75)
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
        HapticManager.notification(.success)
        saved = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
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

    private var color: Color { GlowbiteColors.trafficLight(for: metric.score) }

    var body: some View {
        VStack(spacing: 6) {
            // Mini circle ring
            ZStack {
                Circle()
                    .stroke(GlowbiteColors.softTan, lineWidth: 5)
                    .frame(width: 60, height: 60)

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.0f", metric.score))
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.darkBrown)
            }

            // Metric name + emoji
            Text("\(metric.type.icon) \(metric.type.displayName)")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.lightTaupe)
                .textCase(.uppercase)

            // Status label
            Text(GlowbiteColors.trafficLightLabel(for: metric.score))
                .font(.gbCaption)
                .foregroundStyle(color)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.2)) {
                animatedProgress = metric.score / 100.0
            }
        }
    }
}
