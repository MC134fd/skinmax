import SwiftUI

/// Concept A — "Apple Portrait Frame".
/// The apple mascot is the emotional hero of the result page: a framed portrait
/// captioned "Your skin today", with a glow-score badge tucked into the top-right
/// corner of the frame. Blemishes on the apple mirror the scan 1:1. Metrics live
/// underneath in a 2-column grid of tappable mini-cards that open `SkinDetailView`.
struct FaceScanResultView: View {
    let scan: SkinScan

    @State private var animatedGlow: Double = 0
    @State private var blemishReveal: Double = 0
    @State private var showMetrics = false
    @State private var selectedMetric: SkinMetric?
    @State private var saved = false
    @State private var showSaveToast = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    portraitFrame
                    greetingBlock
                    metricsGrid
                    aiInsightCard
                }
                .padding(.horizontal, GlowbiteSpacing.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
            .background(GlowbiteColors.creamBG.ignoresSafeArea())
            .toolbar { toolbarContent }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
        }
        .overlay { saveToast }
        .sheet(item: $selectedMetric) { metric in
            SkinDetailView(metric: metric)
        }
        .onAppear(perform: runReveal)
    }

    // MARK: - Portrait Frame

    private var portraitFrame: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 10) {
                AppleMascotView(scan: scan, reveal: blemishReveal)
                    .frame(width: 200, height: 200)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)

                Divider()
                    .background(GlowbiteColors.border)
                    .padding(.horizontal, 8)

                VStack(spacing: 4) {
                    Text("YOUR SKIN TODAY")
                        .font(.gbOverline)
                        .tracking(2.5)
                        .foregroundStyle(GlowbiteColors.mediumTaupe)
                    Text(scan.overallMessage.isEmpty ? portraitSubcaption : scan.overallMessage)
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.warmBrown)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 4)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(GlowbiteColors.creamBG)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(GlowbiteColors.white, lineWidth: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(GlowbiteColors.coral.opacity(0.85), lineWidth: 2)
                    .padding(8)
            )
            .shadow(color: GlowbiteColors.elevatedShadowColor, radius: 16, x: 0, y: 6)

            glowBadge
                .offset(x: 6, y: -10)
        }
    }

    private var portraitSubcaption: String {
        switch scan.glowScore {
        case 80...100: return "Dewy and happy ✨"
        case 65..<80:  return "Glowing with room to glow more"
        case 50..<65:  return "A little off, still cute"
        case 35..<50:  return "Tired — we've got you"
        default:        return "Rough day — let's reset together"
        }
    }

    // MARK: - Glow Badge (top-right of frame)

    private var glowBadge: some View {
        ZStack {
            Circle()
                .stroke(GlowbiteColors.softTan, lineWidth: 7)

            Circle()
                .trim(from: 0, to: min(animatedGlow / 100.0, 1.0))
                .stroke(
                    GlowbiteColors.buttonGradient,
                    style: StrokeStyle(lineWidth: 7, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text("\(Int(animatedGlow.rounded()))")
                    .font(.custom("Nunito-ExtraBold", size: 22))
                    .foregroundStyle(GlowbiteColors.darkBrown)
                    .tracking(-0.5)
                Text("GLOW")
                    .font(.gbOverline)
                    .tracking(1.2)
                    .foregroundStyle(GlowbiteColors.mediumTaupe)
                    .padding(.top, -2)
            }
        }
        .frame(width: 82, height: 82)
        .background(
            Circle().fill(GlowbiteColors.white)
        )
        .shadow(color: GlowbiteColors.buttonGlowColor, radius: 14, x: 0, y: 6)
    }

    // MARK: - Greeting

    private var greetingBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(greetingEmoji)
                    .font(.system(size: 26))
                Text(greetingTitle)
                    .font(.gbTitleL)
                    .foregroundStyle(GlowbiteColors.darkBrown)
            }

            if !scan.overallMessage.isEmpty {
                Text(scan.overallMessage)
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.warmBrown)
                    .lineSpacing(3)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var greetingEmoji: String {
        switch scan.glowScore {
        case 80...100: return "🌟"
        case 60..<80:  return "✨"
        default:       return "💫"
        }
    }

    private var greetingTitle: String {
        switch scan.glowScore {
        case 80...100: return "You're glowing, bestie"
        case 65..<80:  return "Looking good today"
        case 50..<65:  return "Doing alright"
        case 35..<50:  return "Skin needs a little love"
        default:       return "Rough day, bestie?"
        }
    }

    // MARK: - Metrics Grid

    private var metricsGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("THE BREAKDOWN")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.mediumTaupe)
                .padding(.leading, 2)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: GlowbiteSpacing.metricGridSpacing),
                GridItem(.flexible(), spacing: GlowbiteSpacing.metricGridSpacing)
            ], spacing: GlowbiteSpacing.metricGridSpacing) {
                ForEach(Array(scan.metrics.enumerated()), id: \.element.id) { index, metric in
                    PortraitMetricCard(metric: metric)
                        .opacity(showMetrics ? 1 : 0)
                        .offset(y: showMetrics ? 0 : 16)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.75)
                                .delay(0.4 + Double(index) * 0.05),
                            value: showMetrics
                        )
                        .onTapGesture {
                            HapticManager.selection()
                            selectedMetric = metric
                        }
                }
            }
        }
    }

    // MARK: - AI Insight

    @ViewBuilder
    private var aiInsightCard: some View {
        if !scan.aiInsight.isEmpty {
            InsightCard(
                emoji: "🍎",
                title: "Apple says",
                message: scan.aiInsight
            )
            .opacity(showMetrics ? 1 : 0)
            .animation(.easeOut(duration: 0.4).delay(0.9), value: showMetrics)
        }
    }

    // MARK: - Toolbar + toast

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: saveScan) {
                Text(saved ? "Saved" : "Save")
                    .font(.gbBodyM)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(GlowbiteColors.buttonGradient)
                    .clipShape(Capsule())
                    .shadow(color: GlowbiteColors.buttonGlowColor, radius: 8, x: 0, y: 3)
            }
            .disabled(saved)
        }
    }

    @ViewBuilder
    private var saveToast: some View {
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

    // MARK: - Reveal / save

    private func runReveal() {
        // Glow counts up immediately.
        withAnimation(.easeOut(duration: 0.9)) {
            animatedGlow = scan.glowScore
        }
        // Apple appears clean, then blemishes fade in after a beat — so the
        // user sees a smooth apple first, then the reveal lands.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeOut(duration: 0.6)) {
                blemishReveal = 1
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            showMetrics = true
        }
    }

    private func saveScan() {
        HapticManager.notification(.success)
        saved = true
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            showSaveToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaveToast = false }
        }
    }
}

// MARK: - Portrait Metric Card

/// Compact tappable mini-card used in the 2-col grid under the portrait.
struct PortraitMetricCard: View {
    let metric: SkinMetric

    @State private var animatedProgress: Double = 0

    private var color: Color { GlowbiteColors.trafficLight(for: metric.score) }
    private var label: String { GlowbiteColors.trafficLightLabel(for: metric.score) }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .stroke(GlowbiteColors.softTan, lineWidth: 4)
                    .frame(width: 40, height: 40)
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 40, height: 40)
                    .rotationEffect(.degrees(-90))
                Text("\(Int(metric.score.rounded()))")
                    .font(.custom("Nunito-ExtraBold", size: 13))
                    .foregroundStyle(GlowbiteColors.darkBrown)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(metric.type.icon)
                        .font(.system(size: 12))
                    Text(metric.type.displayName)
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                        .lineLimit(1)
                }
                Text(label)
                    .font(.gbOverline)
                    .tracking(1.2)
                    .foregroundStyle(color)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(GlowbiteColors.lightTaupe)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 10, x: 0, y: 3)
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.3)) {
                animatedProgress = metric.score / 100.0
            }
        }
    }
}

#if DEBUG
#Preview("Result — Fair") {
    FaceScanResultView(
        scan: SkinScan(
            glowScore: 62,
            metrics: [
                SkinMetric(type: .hydration, score: 58, description: "Needs water"),
                SkinMetric(type: .acne, score: 60, description: "Few spots on cheeks"),
                SkinMetric(type: .darkSpots, score: 58, description: "Temples"),
                SkinMetric(type: .redness, score: 55, description: "Cheeks running hot"),
                SkinMetric(type: .texture, score: 74, description: "Pretty smooth"),
                SkinMetric(type: .pores, score: 78, description: "Tight"),
                SkinMetric(type: .elasticity, score: 80, description: "Bouncy"),
                SkinMetric(type: .wrinkles, score: 76, description: "Smooth")
            ],
            aiInsight: "Drink 2 extra glasses of water and skip hot showers tonight — your skin's asking nicely.",
            overallMessage: "A few cheeky spots — nothing dramatic. Let's give your skin a little extra love."
        )
    )
}

#Preview("Result — Good") {
    FaceScanResultView(
        scan: SkinScan(
            glowScore: 88,
            metrics: SkinMetricType.allCases.map { SkinMetric(type: $0, score: 86) },
            aiInsight: "Your hydration is chef's kiss. Keep that water bottle close and you'll stay in this zone.",
            overallMessage: "Your skin looks fresh and hydrated today. Keep doing whatever you're doing."
        )
    )
}

#Preview("Result — Needs") {
    FaceScanResultView(
        scan: SkinScan(
            glowScore: 34,
            metrics: SkinMetricType.allCases.map { SkinMetric(type: $0, score: 30) },
            aiInsight: "Big ask: hydrate, sleep 8 hrs, SPF tomorrow. We'll rescan in 3 days and watch the glow come back.",
            overallMessage: "Your skin's a bit worn out — we've got you. Small wins today, not a full routine reboot."
        )
    )
}
#endif
