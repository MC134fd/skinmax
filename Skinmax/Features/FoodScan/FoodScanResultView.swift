import SwiftUI

struct FoodScanResultView: View {
    let scan: FoodScan
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var dataStore
    @State private var animatedScore: Double = 0
    @State private var showNutrition = false
    @State private var showBenefits = false
    @State private var saved = false
    @State private var showSaveToast = false

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
                    foodPhoto
                    foodNameSection
                    skinImpactCard
                    nutritionRow
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

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        saveScan()
                    } label: {
                        Text(saved ? "Saved" : "Save")
                            .font(SkinmaxFonts.h3())
                            .foregroundStyle(saved ? SkinmaxColors.warmGray : SkinmaxColors.coral)
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
                    Text("Meal saved!")
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
        .onAppear {
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

    // MARK: - Food Photo
    private var foodPhoto: some View {
        Group {
            if let photoData = scan.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }
        }
    }

    // MARK: - Food Name
    private var foodNameSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(scan.name)
                .font(SkinmaxFonts.h2())
                .foregroundStyle(SkinmaxColors.darkBrown)

            Text("AI Identified · \(scan.createdAt.formatted(date: .omitted, time: .shortened))")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Skin Impact Score Card
    private var skinImpactCard: some View {
        VStack(spacing: 12) {
            Text("SKIN IMPACT")
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .tracking(1)

            Text(String(format: "%.1f", animatedScore))
                .font(SkinmaxFonts.scoreDisplay())
                .foregroundStyle(scoreColor)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(SkinmaxColors.lightTan)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(scoreColor)
                        .frame(width: geo.size.width * (animatedScore / 10.0), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedScore)
                }
            }
            .frame(height: 8)

            Text(scoreLabel)
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.warmGray)
        }
        .padding(SkinmaxSpacing.cardPadding)
        .frame(maxWidth: .infinity)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }

    // MARK: - Nutrition Row
    private var nutritionRow: some View {
        HStack(spacing: 8) {
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
                .padding(.vertical, 12)
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
                    let arrow = effect.direction == .improved ? "↑" : "↓"
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
                    Text("💡")
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

    // MARK: - Save
    private func saveScan() {
        dataStore.saveFoodScan(scan)
        HapticManager.notification(.success)
        saved = true
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            showSaveToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSaveToast = false }
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
