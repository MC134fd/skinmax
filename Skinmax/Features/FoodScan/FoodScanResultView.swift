import SwiftUI

struct FoodScanResultView: View {
    let scan: FoodScan
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var isRevealed = false
    @State private var animatedScore: Double = 0
    @State private var showNutrition = false
    @State private var showBenefits = false
    @State private var glowPulse = false

    private var scoreColor: Color {
        switch scan.skinImpactScore {
        case 8...10: return GlowbiteColors.greenGood
        case 5..<8: return GlowbiteColors.amberFair
        default: return GlowbiteColors.redAlert
        }
    }

    private var scoreEmoji: String {
        switch scan.skinImpactScore {
        case 8...10: return "\u{1F31F}"
        case 5..<8: return "\u{2728}"
        default: return "\u{1F4AB}"
        }
    }

    private var scoreLabel: String {
        switch scan.skinImpactScore {
        case 8...10: return "Your skin's gonna love this"
        case 5..<8: return "Totally okay, bestie"
        default: return "Eh, not your skin's fave"
        }
    }

    private var benefitsTitle: String {
        switch scan.skinImpactScore {
        case 8...10: return "Why it's good"
        case 5..<8: return "Why it's okay"
        default: return "Why it's not great"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    foodNameSection
                    skinImpactCard
                    nutritionGrid
                    benefitsSection
                    skinEffectsSection
                    aiTipCard
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                HapticManager.impact(.medium)
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    isRevealed = true
                    animatedScore = scan.skinImpactScore
                }
                withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                    glowPulse = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showNutrition = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                withAnimation { showBenefits = true }
            }
        }
    }

    // MARK: - Food Name
    private var foodNameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scan.name)
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            Text("AI Identified \u{00B7} \(scan.createdAt.formatted(date: .omitted, time: .shortened))")
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.lightTaupe)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Skin Impact Score Card (Golden Hour + Ambient Glow)
    private var skinImpactCard: some View {
        VStack(spacing: 18) {
            Text("SKIN IMPACT")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.coral.opacity(0.85))

            heroScoreRing

            heroReactionRow
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, GlowbiteSpacing.cardPaddingLarge)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusLarge))
        .shadow(color: GlowbiteColors.elevatedShadowColor, radius: 16, x: 0, y: 6)
    }

    private var cardBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    GlowbiteColors.sunnyButter,
                    GlowbiteColors.peachWash,
                    GlowbiteColors.coral.opacity(0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Soft peach drift blob (top-left) for dynamic warmth
            Circle()
                .fill(GlowbiteColors.coral.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 50)
                .offset(x: -80, y: -60)
                .scaleEffect(glowPulse ? 1.08 : 0.95)

            // Sunny butter drift blob (bottom-right) for depth
            Circle()
                .fill(GlowbiteColors.sunnyButter.opacity(0.9))
                .frame(width: 180, height: 180)
                .blur(radius: 45)
                .offset(x: 70, y: 80)
                .scaleEffect(glowPulse ? 0.95 : 1.08)
        }
    }

    private var heroScoreRing: some View {
        ZStack {
            // Ambient score-colored glow behind ring
            Circle()
                .fill(scoreColor.opacity(0.18))
                .frame(width: 180, height: 180)
                .blur(radius: 30)
                .scaleEffect(glowPulse ? 1.08 : 0.96)
                .opacity(isRevealed ? 1 : 0)

            Circle()
                .stroke(GlowbiteColors.coral.opacity(0.12), lineWidth: 14)
                .frame(width: 140, height: 140)

            Circle()
                .trim(from: 0, to: animatedScore / 10.0)
                .stroke(
                    LinearGradient(
                        colors: [scoreColor, scoreColor.opacity(0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 0) {
                Text(String(format: "%.1f", animatedScore))
                    .font(.gbDisplayXL)
                    .tracking(-1.0)
                    .foregroundStyle(GlowbiteColors.darkBrown)
                    .contentTransition(.numericText(countsDown: false))
                    .opacity(isRevealed ? 1 : 0)

                Text("/ 10")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.mediumTaupe)
                    .opacity(isRevealed ? 1 : 0)
            }
        }
    }

    private var heroReactionRow: some View {
        HStack(spacing: 8) {
            Text(scoreEmoji)
                .font(.system(size: 20))

            Text("\(scoreLabel) \u{2728}")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.warmBrown)
                .multilineTextAlignment(.leading)
        }
        .opacity(isRevealed ? 1 : 0)
        .animation(.easeOut(duration: 0.25).delay(0.45), value: isRevealed)
    }

    // MARK: - Nutrition Grid
    private var nutritionGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
            ForEach(Array(nutritionItems.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 4) {
                    Text(item.value)
                        .font(.gbBodyL)
                        .foregroundStyle(GlowbiteColors.darkBrown)

                    Text(item.label)
                        .font(.gbOverline)
                        .tracking(2.0)
                        .foregroundStyle(GlowbiteColors.lightTaupe)
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(GlowbiteColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
                .opacity(showNutrition ? 1 : 0)
                .offset(y: showNutrition ? 0 : 16)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.75)
                    .delay(Double(index) * 0.08),
                    value: showNutrition
                )
            }
        }
    }

    private var nutritionItems: [(value: String, label: String)] {
        [
            ("\(scan.calories)", "CAL"),
            (String(format: "%.0fg", scan.protein), "PROTEIN"),
            (String(format: "%.0fg", scan.fat), "FAT"),
            (String(format: "%.0fg", scan.carbs), "CARBS"),
            (String(format: "%.0fg", scan.fiber), "FIBER"),
            (String(format: "%.0fg", scan.sugar), "SUGAR"),
            (String(format: "%.1fg", scan.sodium), "SODIUM"),
        ]
    }

    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(benefitsTitle)
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            ForEach(Array(scan.benefits.enumerated()), id: \.offset) { _, benefit in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(scan.skinImpactScore >= 5 ? GlowbiteColors.greenGood : GlowbiteColors.redAlert)
                        .frame(width: 6, height: 6)
                        .padding(.top, 5)

                    Text(benefit)
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.warmBrown)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowbiteSpacing.cardPadding)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        .opacity(showBenefits ? 1 : 0)
        .animation(.easeIn(duration: 0.3), value: showBenefits)
    }

    // MARK: - Skin Effects Tags
    private var skinEffectsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Skin Effects")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            FlowLayout(spacing: 8) {
                ForEach(scan.skinEffects) { effect in
                    let arrow = effect.direction == .improved ? "\u{2191}" : "\u{2193}"
                    let tint = effect.direction == .improved ? GlowbiteColors.greenGood : GlowbiteColors.redAlert

                    HStack(spacing: 4) {
                        Text(effect.metricType.displayName)
                            .foregroundStyle(GlowbiteColors.darkBrown)
                        Text(arrow)
                            .foregroundStyle(tint)
                    }
                    .font(.gbCaption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(GlowbiteColors.peachWash)
                    .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.tagCornerRadius))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowbiteSpacing.cardPadding)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        .opacity(showBenefits ? 1 : 0)
        .animation(.easeIn(duration: 0.3).delay(0.1), value: showBenefits)
    }

    // MARK: - AI Tip Card
    private var aiTipCard: some View {
        Group {
            if let tip = scan.aiTip {
                HStack(alignment: .top, spacing: 10) {
                    Text("\u{1F4A1}")
                        .font(.system(size: 20))

                    Text(tip)
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                        .lineSpacing(3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(GlowbiteColors.peachWash)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - Flow Layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}
