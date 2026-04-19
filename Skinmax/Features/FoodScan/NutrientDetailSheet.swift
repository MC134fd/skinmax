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

    var unit: String {
        switch self {
        case .sodium: return "mg"
        default: return "g"
        }
    }

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

    var info: NutrientInfo { NutrientInfo.all[self]! }
}

// MARK: - Nutrient Info

struct NutrientInfo {
    let tagline: String
    let whyBodyCares: String
    let whySkinCares: String
    let scienceSnapshot: [String]
    let tooLittle: String
    let tooMuch: String
    let goodSources: [(emoji: String, name: String)]
    var sourcesTitle: String = "Skin-friendly picks"

    // MARK: - All Nutrients

    static let all: [NutrientType: NutrientInfo] = [
        .protein: NutrientInfo(
            tagline: "The raw material for collagen \u{2014} your skin's bounce system \u{1F4AA}",
            whyBodyCares: "Protein breaks down into amino acids that your body uses for everything from muscle repair to immune function. It keeps you full longer and stabilizes blood sugar between meals.",
            whySkinCares: "Your skin is literally built from protein \u{2014} collagen and elastin are proteins that give it bounce and firmness. Without enough amino acids (especially proline and glycine), your skin can't turn over collagen properly, so things start looking dull and healing slows down.",
            scienceSnapshot: [
                "Collagen is ~30% of total body protein \u{2014} dietary protein supplies the amino acids to keep it turning over (systematic review, Nutrients 2020).",
                "A 16-week omega-3 + protein intervention reduced inflammatory acne lesions by ~42% in a randomized controlled trial.",
                "Chronic low protein intake impairs the skin barrier and slows wound healing, per clinical nutrition consensus.",
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
        ),
        .fat: NutrientInfo(
            tagline: "Good fats protect your barrier; bad fats fire up inflammation \u{1F525}",
            whyBodyCares: "Fat is essential for absorbing vitamins A, D, E, and K, cushioning organs, and building cell membranes. Omega-3 fatty acids are powerful anti-inflammatory agents throughout your whole body.",
            whySkinCares: "Your skin's outer layer is a lipid barrier \u{2014} healthy fats keep moisture locked in and irritants out. Omega-3s directly calm redness and inflammation, while trans and excess saturated fats can ramp up sebum production and breakouts.",
            scienceSnapshot: [
                "A 16-week fish oil randomized trial showed a significant drop in inflammatory acne lesions via cytokine modulation.",
                "Trans and excess saturated fats raise IGF-1, a hormone linked to increased sebum and breakouts (meta-analysis, JAAD 2018).",
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
        ),
        .carbs: NutrientInfo(
            tagline: "Low-GI carbs keep blood sugar steady \u{2014} and your skin calm \u{2728}",
            whyBodyCares: "Carbs are your brain's and muscles' primary fuel source. The key is quality: whole grains and complex carbs give sustained energy, while refined carbs cause blood sugar spikes that trigger insulin surges.",
            whySkinCares: "High-glycemic carbs spike insulin and IGF-1, which ramp up sebum production \u{2014} hello, breakouts. Over time, excess sugar from refined carbs bonds to collagen through glycation, making skin stiff and dull. Low-GI choices give you energy without the skin drama.",
            scienceSnapshot: [
                "A randomized trial on low-GI diets showed a measurable drop in IGF-1, correlating with fewer acne lesions.",
                "A 2022 systematic review found high-GI diets have a modest but consistent pro-acnegenic effect across populations.",
                "Glycation creates AGEs (advanced glycation end-products) that stiffen collagen fibers \u{2014} sometimes called \"sugar sag.\"",
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
        ),
        .fiber: NutrientInfo(
            tagline: "Feed your gut, glow on the outside \u{2014} the gut-skin connection \u{1F331}",
            whyBodyCares: "Fiber feeds the beneficial bacteria in your gut, keeping digestion regular and your microbiome balanced. Those bacteria produce short-chain fatty acids (SCFAs) like butyrate that strengthen your gut lining and calm systemic inflammation.",
            whySkinCares: "The gut-skin axis is real \u{2014} when your gut is inflamed or out of balance, it shows up on your face as breakouts, redness, or dullness. A fiber-rich diet supports the microbial ecosystem that keeps inflammation in check, so your skin stays calmer.",
            scienceSnapshot: [
                "Higher fiber intake correlates with lower C-reactive protein (CRP), a systemic inflammation marker tied to acne and redness.",
                "Gut bacteria ferment fiber into butyrate and other SCFAs that reinforce the intestinal barrier and modulate skin immunity.",
                "Early clinical evidence links gut dysbiosis to acne, eczema, and rosacea through the gut-skin axis.",
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
        ),
        .sugar: NutrientInfo(
            tagline: "Sugar sticks to collagen \u{2014} literally. That's called glycation \u{1F36D}",
            whyBodyCares: "Your body uses glucose for quick energy, but it can make all it needs from complex carbs. Added sugar spikes blood sugar fast, stresses your pancreas, and feeds inflammatory pathways throughout your body.",
            whySkinCares: "Excess sugar reacts with proteins in your skin through glycation, forming AGEs that make collagen stiff, brittle, and dull. It also triggers insulin-driven sebum production. Your skin basically ages faster and breaks out more \u{2014} not a great combo.",
            scienceSnapshot: [
                "Over 20 distinct AGE species have been identified in human skin, increasing with both age and dietary sugar exposure.",
                "AGEs cross-link collagen fibers, reducing elasticity and contributing to wrinkles and sagging (clinical review, Dermato-Endocrinology).",
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
        ),
        .sodium: NutrientInfo(
            tagline: "Too much salt = puffy face mornings. Your skin holds onto water \u{1F4A7}",
            whyBodyCares: "Sodium helps regulate fluid balance, nerve signals, and muscle contractions. But most people eat nearly double the recommended amount, which causes the body to retain excess water and raises blood pressure over time.",
            whySkinCares: "When you overdo sodium, your body holds onto fluid \u{2014} and that puffiness loves to show up around your eyes and jawline first thing in the morning. Over time, excess sodium can dehydrate skin cells and trigger local inflammatory responses that dull your glow.",
            scienceSnapshot: [
                "Average intake is ~3,400 mg/day vs. the WHO recommendation of <2,000 mg \u{2014} most people eat nearly double.",
                "Sodium accumulates in skin tissue and can trigger local inflammatory responses independent of blood pressure effects.",
                "Reducing sodium intake + increasing water can visibly reduce facial puffiness within 48\u{2013}72 hours.",
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
        ),
    ]
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
                bodyCaresCard
                skinCaresCard
                scienceCard
                tooLittleTooMuchCard
                sourcesCard
                disclaimer
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
                .font(.gbDisplayL)

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

    // MARK: - Why your body cares
    private var bodyCaresCard: some View {
        sectionCard(title: "Why your body cares", body: info.whyBodyCares)
    }

    // MARK: - Why your skin cares
    private var skinCaresCard: some View {
        sectionCard(title: "Why your skin cares", body: info.whySkinCares)
    }

    // MARK: - The science snapshot
    private var scienceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The science snapshot")
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            ForEach(Array(info.scienceSnapshot.enumerated()), id: \.offset) { _, bullet in
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
                            .font(.gbCaption)
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

    // MARK: - Disclaimer
    private var disclaimer: some View {
        Text("For education only \u{2014} not medical or dietary advice. Talk to a healthcare professional about your specific needs.")
            .font(.gbCaption)
            .foregroundStyle(GlowbiteColors.lightTaupe)
            .multilineTextAlignment(.center)
            .padding(.horizontal, GlowbiteSpacing.md)
    }

    // MARK: - Helpers

    private func sectionCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.gbBodyM)
                .foregroundStyle(GlowbiteColors.darkBrown)

            Text(body)
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

    private var formattedAmount: String {
        if nutrient == .sodium {
            let mg = amount * 1000
            return String(format: "%.0f %@", mg, nutrient.unit)
        }
        return String(format: "%.0f%@", amount, nutrient.unit)
    }
}
