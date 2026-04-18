import SwiftUI

// MARK: - Nutrient Type

enum NutrientType: String, Identifiable, CaseIterable {
    case protein, fat, carbs, fiber, sugar, sodium

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .protein: return "Protein"
        case .fat: return "Fat"
        case .carbs: return "Carbs"
        case .fiber: return "Fiber"
        case .sugar: return "Sugar"
        case .sodium: return "Sodium"
        }
    }

    var emoji: String {
        switch self {
        case .protein: return "\u{1F95A}"
        case .fat: return "\u{1F951}"
        case .carbs: return "\u{1F360}"
        case .fiber: return "\u{1F33E}"
        case .sugar: return "\u{1F36F}"
        case .sodium: return "\u{1F9C2}"
        }
    }

    var unit: String { "g" }

    var accentColor: Color {
        switch self {
        case .protein: return GlowbiteColors.nutrientProtein
        case .fat: return GlowbiteColors.nutrientFat
        case .carbs: return GlowbiteColors.nutrientCarbs
        case .fiber: return GlowbiteColors.nutrientFiber
        case .sugar: return GlowbiteColors.nutrientSugar
        case .sodium: return GlowbiteColors.nutrientSodium
        }
    }

    var info: NutrientInfo {
        switch self {
        case .protein: return .protein
        case .fat: return .fat
        case .carbs: return .carbs
        case .fiber: return .fiber
        case .sugar: return .sugar
        case .sodium: return .sodium
        }
    }
}

// MARK: - Nutrient Info

struct NutrientInfo {
    let tagline: String
    let whyItMatters: String
    let skinScience: [String]
    let tooLittle: String
    let tooMuch: String
    let goodSources: [(emoji: String, name: String)]
    /// Override section title for sources (e.g. "Flavor swaps" for sodium)
    var sourcesTitle: String = "Skin-friendly picks"

    // MARK: - Curated Content

    static let protein = NutrientInfo(
        tagline: "The raw material for collagen \u{2014} your skin's bounce system.",
        whyItMatters: "Your body breaks protein into amino acids that rebuild collagen and elastin. Without enough, skin loses firmness and wounds heal slower.",
        skinScience: [
            "Collagen is ~30% of total body protein \u{2014} dietary protein supplies the amino acids (proline, glycine) to keep it turning over.",
            "A 16-week omega-3 + protein intervention reduced inflammatory acne lesions by ~42% in one RCT.",
            "Chronic low protein intake impairs the skin barrier and slows wound healing.",
        ],
        tooLittle: "Slower collagen turnover, dull tone, weaker skin barrier",
        tooMuch: "Excess protein is rarely a skin issue \u{2014} kidneys handle the surplus",
        goodSources: [
            ("\u{1F95A}", "Eggs"),
            ("\u{1F41F}", "Salmon"),
            ("\u{1F357}", "Chicken"),
            ("\u{1FAD8}", "Beans"),
            ("\u{1F95B}", "Greek yogurt"),
            ("\u{1FAD8}", "Lentils"),
        ]
    )

    static let fat = NutrientInfo(
        tagline: "Omega-3s calm inflammation; trans fats do the opposite.",
        whyItMatters: "Healthy fats form the lipid barrier that keeps moisture in and irritants out. Omega-3 fatty acids are directly anti-inflammatory for skin.",
        skinScience: [
            "A 16-week fish oil trial showed a significant drop in inflammatory acne lesions via cytokine modulation.",
            "Trans and excess saturated fats can raise IGF-1, a hormone linked to increased sebum and breakouts.",
            "Zero-fat diets compromise the skin's lipid barrier, leading to dryness, flaking, and sensitivity.",
        ],
        tooLittle: "Dry, flaky skin; weakened barrier; increased sensitivity",
        tooMuch: "Excess saturated/trans fat can trigger inflammation and breakouts",
        goodSources: [
            ("\u{1F951}", "Avocado"),
            ("\u{1F41F}", "Salmon"),
            ("\u{1F330}", "Walnuts"),
            ("\u{1FAD2}", "Olive oil"),
            ("\u{1F965}", "Coconut"),
            ("\u{1F330}", "Chia seeds"),
        ]
    )

    static let carbs = NutrientInfo(
        tagline: "Low-GI carbs keep blood sugar steady \u{2014} and your skin calm.",
        whyItMatters: "High-glycemic carbs spike insulin and IGF-1, which ramp up sebum production. Low-GI choices give you energy without the skin drama.",
        skinScience: [
            "An RCT on low-GI diets showed a measurable drop in IGF-1, correlating with fewer acne lesions.",
            "A 2022 systematic review found high-GI diets have a modest but consistent pro-acnegenic effect.",
            "Glycation (sugar bonding to collagen) creates AGEs that stiffen skin \u{2014} sometimes called \"sugar sag.\"",
        ],
        tooLittle: "Low energy, but not a direct skin concern unless overall nutrition suffers",
        tooMuch: "Insulin spikes, excess sebum, glycation damage, dull complexion",
        goodSources: [
            ("\u{1F360}", "Sweet potato"),
            ("\u{1FAD0}", "Berries"),
            ("\u{1F35E}", "Oats"),
            ("\u{1F96C}", "Leafy greens"),
            ("\u{1FAD8}", "Beans"),
            ("\u{1F35A}", "Brown rice"),
        ]
    )

    static let fiber = NutrientInfo(
        tagline: "Feed your gut, glow on the outside \u{2014} the gut-skin connection.",
        whyItMatters: "Fiber feeds beneficial gut bacteria that produce short-chain fatty acids. These strengthen your gut lining and reduce systemic inflammation that shows up on skin.",
        skinScience: [
            "Higher fiber intake correlates with lower C-reactive protein (CRP), a systemic inflammation marker tied to acne and redness.",
            "Gut bacteria ferment fiber into butyrate and other SCFAs that reinforce the intestinal barrier and modulate skin immunity.",
            "The gut-skin axis is an active research area \u{2014} early evidence links dysbiosis to acne, eczema, and rosacea.",
        ],
        tooLittle: "Gut imbalance, higher inflammation, potential breakouts",
        tooMuch: "Bloating and discomfort, but no direct skin harm",
        goodSources: [
            ("\u{1F951}", "Avocado"),
            ("\u{1FAD8}", "Beans"),
            ("\u{1F34E}", "Apples"),
            ("\u{1F35E}", "Oats"),
            ("\u{1F966}", "Broccoli"),
            ("\u{1FAD0}", "Raspberries"),
        ]
    )

    static let sugar = NutrientInfo(
        tagline: "Sugar sticks to collagen \u{2014} literally. That's called glycation.",
        whyItMatters: "Excess sugar reacts with proteins in your skin through glycation, forming advanced glycation end-products (AGEs) that make collagen stiff, brittle, and dull.",
        skinScience: [
            "Over 20 distinct AGE species have been identified in human skin, increasing with age and sugar exposure.",
            "AGEs cross-link collagen fibers, reducing elasticity and contributing to wrinkles and sagging.",
            "AGEs activate RAGE receptors, triggering NF-\u{03BA}B inflammatory pathways that worsen acne and redness.",
        ],
        tooLittle: "Not a skin concern \u{2014} your body makes all the glucose it needs from complex carbs",
        tooMuch: "Glycation, dullness, premature wrinkles, insulin-driven breakouts",
        goodSources: [
            ("\u{1FAD0}", "Berries"),
            ("\u{1F34E}", "Apples"),
            ("\u{1F347}", "Grapes"),
            ("\u{1F34A}", "Oranges"),
            ("\u{1F352}", "Cherries"),
            ("\u{1F353}", "Strawberries"),
        ],
        sourcesTitle: "If you're craving sweet"
    )

    static let sodium = NutrientInfo(
        tagline: "Too much salt = puffy face mornings. Your skin holds onto water.",
        whyItMatters: "Excess sodium causes your body to retain fluid, leading to puffiness \u{2014} especially around the eyes. It can also dehydrate skin cells over time.",
        skinScience: [
            "Average intake is ~3,400 mg/day vs. the WHO recommendation of <2,000 mg \u{2014} most people eat nearly double.",
            "Sodium accumulates in skin tissue and can trigger local inflammatory responses independent of blood pressure.",
            "Cutting sodium + increasing water intake can visibly reduce facial puffiness within 48\u{2013}72 hours.",
        ],
        tooLittle: "Rare and not a skin concern for most people",
        tooMuch: "Facial puffiness, under-eye bags, dehydrated-looking skin, inflammation",
        goodSources: [
            ("\u{1F34B}", "Lemon juice"),
            ("\u{1F33F}", "Fresh herbs"),
            ("\u{1F9C4}", "Garlic"),
            ("\u{1FAD0}", "Ginger"),
            ("\u{1F336}\u{FE0F}", "Chili"),
            ("\u{1F9C5}", "Onion"),
        ],
        sourcesTitle: "Flavor swaps"
    )
}

// MARK: - Nutrient Detail Sheet

struct NutrientDetailSheet: View {
    let nutrient: NutrientType
    let amount: Double
    let onDismiss: () -> Void

    private var info: NutrientInfo { nutrient.info }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 18) {
                header
                heroCard
                whyItMattersCard
                skinScienceCard
                tooLittleTooMuchCard
                sourcesCard
            }
            .padding(.horizontal, GlowbiteSpacing.screenPadding)
            .padding(.top, 12)
            .padding(.bottom, 40)
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(GlowbiteColors.creamBG)
    }

    // MARK: - Header
    private var header: some View {
        HStack {
            Text(nutrient.displayName)
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            Spacer()

            Button {
                HapticManager.impact(.light)
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
                    .frame(width: 32, height: 32)
                    .background(GlowbiteColors.peachWash)
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Hero Card
    private var heroCard: some View {
        VStack(spacing: 14) {
            Text("IN THIS MEAL")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(nutrient.accentColor.opacity(0.85))

            Text(nutrient.emoji)
                .font(.system(size: 44))

            Text(formattedAmount)
                .font(.gbDisplayL)
                .foregroundStyle(GlowbiteColors.darkBrown)

            Text(info.tagline)
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.warmBrown)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, GlowbiteSpacing.cardPaddingLarge)
        .background(heroBackground)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadiusLarge, style: .continuous))
        .shadow(color: GlowbiteColors.elevatedShadowColor, radius: 16, x: 0, y: 6)
    }

    private var heroBackground: some View {
        ZStack {
            LinearGradient(
                colors: [
                    GlowbiteColors.sunnyButter,
                    GlowbiteColors.peachWash,
                    nutrient.accentColor.opacity(0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(nutrient.accentColor.opacity(0.08))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: -70, y: -50)

            Circle()
                .fill(GlowbiteColors.sunnyButter.opacity(0.8))
                .frame(width: 160, height: 160)
                .blur(radius: 40)
                .offset(x: 60, y: 70)
        }
    }

    // MARK: - Why It Matters
    private var whyItMattersCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Why it matters for your skin")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            Text(info.whyItMatters)
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.warmBrown)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowbiteSpacing.cardPadding)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius, style: .continuous))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    // MARK: - Skin Science
    private var skinScienceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skin science")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            ForEach(Array(info.skinScience.enumerated()), id: \.offset) { _, bullet in
                HStack(alignment: .top, spacing: 10) {
                    Text("\u{2726}")
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.coral)

                    Text(bullet)
                        .font(.gbBodyM)
                        .foregroundStyle(GlowbiteColors.warmBrown)
                        .lineSpacing(2)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowbiteSpacing.cardPadding)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius, style: .continuous))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    // MARK: - Too Little vs Too Much
    private var tooLittleTooMuchCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Too little vs too much")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            HStack(alignment: .top, spacing: 10) {
                // Too little
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOO LITTLE")
                        .font(.gbOverline)
                        .tracking(1.5)
                        .foregroundStyle(GlowbiteColors.greenGood)

                    Text(info.tooLittle)
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.warmBrown)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(GlowbiteColors.greenGood.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                // Too much
                VStack(alignment: .leading, spacing: 6) {
                    Text("TOO MUCH")
                        .font(.gbOverline)
                        .tracking(1.5)
                        .foregroundStyle(GlowbiteColors.redAlert)

                    Text(info.tooMuch)
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.warmBrown)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(GlowbiteColors.redAlert.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowbiteSpacing.cardPadding)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius, style: .continuous))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    // MARK: - Good Sources / Swaps
    private var sourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(info.sourcesTitle)
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            FlowLayout(spacing: 8) {
                ForEach(Array(info.goodSources.enumerated()), id: \.offset) { _, source in
                    HStack(spacing: 4) {
                        Text(source.emoji)
                            .font(.system(size: 14))
                        Text(source.name)
                            .font(.gbCaption)
                            .foregroundStyle(GlowbiteColors.darkBrown)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(GlowbiteColors.peachWash)
                    .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.tagCornerRadius, style: .continuous))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(GlowbiteSpacing.cardPadding)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius, style: .continuous))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }

    // MARK: - Formatting
    private var formattedAmount: String {
        if nutrient == .sodium {
            return String(format: "%.1f%@", amount, nutrient.unit)
        }
        return String(format: "%.0f%@", amount, nutrient.unit)
    }
}
