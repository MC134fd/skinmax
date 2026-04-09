import SwiftUI

struct FoodScanResultView: View {
    let scan: FoodScan
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var animatedScore: Double = 0
    @State private var showNutrition = false
    @State private var showBenefits = false

    private var scoreColor: Color {
        switch scan.skinImpactScore {
        case 8...10: return SkinmaxColors.greenGood
        case 5..<8: return SkinmaxColors.amberFair
        default: return SkinmaxColors.redAlert
        }
    }

    private var scoreLabel: String {
        switch scan.skinImpactScore {
        case 8...10: return "Great for your skin!"
        case 5..<8: return "Okay for your skin"
        default: return "Not ideal for your skin"
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
        }
        .onAppear {
            dataStore.saveFoodScan(scan)
            withAnimation(.easeOut(duration: 0.8)) {
                animatedScore = scan.skinImpactScore
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    showNutrition = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation { showBenefits = true }
            }
            HapticManager.impact(.medium)
        }
    }

    // MARK: - Food Name
    private var foodNameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scan.name)
                .font(SkinmaxFonts.h2())
                .foregroundStyle(SkinmaxColors.darkBrown)

            Text("AI Identified \u{00B7} \(scan.createdAt.formatted(date: .omitted, time: .shortened))")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Skin Impact Score Card (Circular Ring)
    private var skinImpactCard: some View {
        VStack(spacing: 14) {
            Text("SKIN IMPACT")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(.white.opacity(0.6))
                .tracking(1)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 8)
                    .frame(width: 110, height: 110)

                Circle()
                    .trim(from: 0, to: animatedScore / 10.0)
                    .stroke(
                        scoreColor,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 110, height: 110)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedScore)

                Text(String(format: "%.1f", animatedScore))
                    .font(.custom("Nunito-Bold", size: 36))
                    .foregroundStyle(scoreColor)
            }

            Text(scoreLabel)
                .font(SkinmaxFonts.h3())
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
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

    // MARK: - Nutrition Grid (2x2)
    private var nutritionGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8),
        ], spacing: 8) {
            ForEach(Array(nutritionItems.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 4) {
                    Text(item.value)
                        .font(.custom("Nunito-SemiBold", size: 16))
                        .foregroundStyle(SkinmaxColors.darkBrown)

                    Text(item.label)
                        .font(SkinmaxFonts.small())
                        .foregroundStyle(SkinmaxColors.mutedTan)
                        .textCase(.uppercase)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(SkinmaxColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
                .opacity(showNutrition ? 1 : 0)
                .offset(y: showNutrition ? 0 : 16)
                .animation(
                    .spring(response: 0.4, dampingFraction: 0.8)
                    .delay(Double(index) * 0.1),
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
        ]
    }

    // MARK: - Benefits Section
    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(benefitsTitle)
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            ForEach(Array(scan.benefits.enumerated()), id: \.offset) { _, benefit in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(scan.skinImpactScore >= 5 ? SkinmaxColors.greenGood : SkinmaxColors.redAlert)
                        .frame(width: 6, height: 6)
                        .padding(.top, 5)

                    Text(benefit)
                        .font(SkinmaxFonts.body())
                        .foregroundStyle(SkinmaxColors.warmGray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SkinmaxSpacing.cardPadding)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        .opacity(showBenefits ? 1 : 0)
        .animation(.easeIn(duration: 0.3), value: showBenefits)
    }

    // MARK: - Skin Effects Tags
    private var skinEffectsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Skin Effects")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)

            FlowLayout(spacing: 8) {
                ForEach(scan.skinEffects) { effect in
                    let arrow = effect.direction == .improved ? "\u{2191}" : "\u{2193}"
                    let tint = effect.direction == .improved ? SkinmaxColors.greenGood : SkinmaxColors.redAlert

                    HStack(spacing: 4) {
                        Text(effect.metricType.displayName)
                            .foregroundStyle(SkinmaxColors.darkBrown)
                        Text(arrow)
                            .foregroundStyle(tint)
                    }
                    .font(SkinmaxFonts.caption())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(SkinmaxColors.peachWash)
                    .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.tagCornerRadius))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SkinmaxSpacing.cardPadding)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
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
                        .font(SkinmaxFonts.body())
                        .foregroundStyle(SkinmaxColors.darkBrown)
                        .lineSpacing(3)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(SkinmaxColors.peachWash)
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
