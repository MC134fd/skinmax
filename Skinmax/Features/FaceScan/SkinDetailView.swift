import SwiftUI

struct SkinDetailView: View {
    let metric: SkinMetric
    @Environment(\.dismiss) private var dismiss
    @State private var animatedProgress: Double = 0

    private var color: Color { GlowbiteColors.trafficLight(for: metric.score) }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    scoreRing
                    severityBadge
                    descriptionSection
                    tipsSection
                }
                .padding(.horizontal, GlowbiteSpacing.screenPadding)
                .padding(.bottom, 40)
            }
            .background(GlowbiteColors.creamBG.ignoresSafeArea())
            .navigationTitle(metric.type.displayName)
            .navigationBarTitleDisplayMode(.inline)
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
            .navigationBarBackButtonHidden()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                animatedProgress = metric.score / 100.0
            }
        }
    }

    // MARK: - Score Ring
    private var scoreRing: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(GlowbiteColors.softTan, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(String(format: "%.0f", metric.score))
                        .font(.gbDisplayL)
                        .tracking(-1.0)
                        .foregroundStyle(GlowbiteColors.darkBrown)

                    Text(metric.type.icon)
                        .font(.system(size: 16))
                }
            }

            Text(metric.type.displayName)
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.darkBrown)
        }
        .padding(.top, 20)
    }

    // MARK: - Severity Badge
    private var severityBadge: some View {
        HStack(spacing: 8) {
            TagPill(text: metric.severity.capitalized)

            Text(GlowbiteColors.trafficLightLabel(for: metric.score))
                .font(.gbCaption)
                .foregroundStyle(color)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.tagCornerRadius))
        }
    }

    // MARK: - Description
    @ViewBuilder
    private var descriptionSection: some View {
        if !metric.description.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("About")
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Text(metric.description)
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.warmBrown)
                    .lineSpacing(3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(GlowbiteSpacing.cardPadding)
            .background(GlowbiteColors.white)
            .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
            .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        }
    }

    // MARK: - Tips
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tips to Improve")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            ForEach(Array(tipsForMetric.enumerated()), id: \.offset) { _, tip in
                HStack(alignment: .top, spacing: 10) {
                    Text("✦")
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.coral)

                    Text(tip)
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.warmBrown)
                        .lineSpacing(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowbiteSpacing.cardPadding)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    private var tipsForMetric: [String] {
        switch metric.type {
        case .hydration:
            return [
                "Drink at least 8 glasses of water daily",
                "Eat water-rich foods like cucumber, watermelon, and celery",
                "Use a hyaluronic acid serum morning and night",
            ]
        case .acne:
            return [
                "Reduce dairy and high-sugar foods in your diet",
                "Change your pillowcase every 2-3 days",
                "Avoid touching your face throughout the day",
            ]
        case .texture:
            return [
                "Exfoliate gently 2-3 times per week with AHA/BHA",
                "Use a vitamin C serum in the morning",
                "Always apply SPF 30+ sunscreen daily",
            ]
        case .darkSpots:
            return [
                "Apply vitamin C serum to fade existing spots",
                "Wear sunscreen daily — UV exposure darkens spots",
                "Eat foods rich in antioxidants like berries and leafy greens",
            ]
        case .redness:
            return [
                "Eat anti-inflammatory foods like salmon and walnuts",
                "Avoid spicy food and alcohol which trigger redness",
                "Use gentle, fragrance-free skincare products",
            ]
        case .pores:
            return [
                "Use niacinamide serum to minimize pore appearance",
                "Double cleanse at night to remove all buildup",
                "Avoid heavy, comedogenic moisturizers",
            ]
        case .wrinkles:
            return [
                "Apply retinol at night to boost collagen production",
                "Stay hydrated — dehydrated skin shows more lines",
                "Eat collagen-rich foods like bone broth and citrus fruits",
            ]
        case .elasticity:
            return [
                "Massage your face gently to improve circulation",
                "Eat protein-rich foods to support collagen",
                "Get 7-9 hours of sleep for skin repair",
            ]
        }
    }
}
