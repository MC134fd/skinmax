import SwiftUI

/// Skinmax apple mascot, rendered entirely in SwiftUI so it matches the app
/// icon exactly and keeps a clean transparent background at any size.
///
/// Blemish overlays mirror a `SkinScan` 1:1: blemishes become visible when a
/// metric score drops below 70; intensity scales as the score drops toward 0.
/// When every metric is ≥70, the apple gets extra sparkles + a stronger shine.
///
/// The view draws onto a square coordinate space. Place it inside a fixed
/// square frame (e.g. `.frame(width: 220, height: 220)`).
struct AppleMascotView: View {
    let scan: SkinScan
    /// 0 = no blemishes shown, 1 = fully revealed. Lets callers choreograph
    /// the reveal after results land (e.g. 0 → 1 over ~0.6s).
    var reveal: Double = 1

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            ZStack {
                AppleBody(side: side, tier: GlowTier(glowScore: scan.glowScore))
                blemishLayer(side: side)
                    .frame(width: side, height: side)
                    .opacity(reveal)
                    .animation(.easeOut(duration: 0.5), value: reveal)
            }
            .frame(width: side, height: side)
            .frame(width: geo.size.width, height: geo.size.height)
            // Rasterize the entire mascot to a Metal-backed bitmap so scrolling
            // composites one texture instead of re-rendering ~30 shapes, two
            // blend-mode layers, and several offscreen blurs every frame.
            // The mascot is static after the reveal lands, so caching is safe.
            .drawingGroup(opaque: false)
        }
    }

    // MARK: - Blemish layer

    @ViewBuilder
    private func blemishLayer(side: CGFloat) -> some View {
        let scores = ScoreMap(metrics: scan.metrics)

        ZStack {
            hydrationLayer(scores: scores, side: side)
            rednessLayer(scores: scores, side: side)
            darkSpotsLayer(scores: scores, side: side)
            acneLayer(scores: scores, side: side)
            textureLayer(scores: scores, side: side)
            poresLayer(scores: scores, side: side)
            wrinklesLayer(scores: scores, side: side)
            elasticityLayer(scores: scores, side: side)
            allClearGlow(scores: scores, side: side)
        }
        .allowsHitTesting(false)
        .animation(.easeOut(duration: 0.35), value: scan.id)
    }

    // MARK: - Per-metric layers
    //
    // All positions are fractions (0..1) of the mascot's square side, using
    // the coordinate system defined in `AppleBody`:
    //   face center ≈ (0.50, 0.57)
    //   eye line    ≈ y 0.54
    //   cheek line  ≈ y 0.66
    //   forehead    ≈ y 0.42
    //   chin        ≈ y 0.78
    //   left/right cheeks ≈ x 0.33 / x 0.67

    @ViewBuilder
    private func hydrationLayer(scores: ScoreMap, side: CGFloat) -> some View {
        let score = scores.hydration
        if score < 70 {
            let strength = BlemishIntensity.opacity(for: score)
            // Matte veil across face area
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            GlowbiteColors.creamBG.opacity(0.32 * strength),
                            GlowbiteColors.creamBG.opacity(0)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: side * 0.40
                    )
                )
                .blendMode(.softLight)
                .frame(width: side * 0.75, height: side * 0.75)
                .position(x: side * 0.50, y: side * 0.57)

            // Dry lines on cheeks
            dryLine(x: 0.32, y: 0.70, length: 0.09, angle: -14, side: side, opacity: strength)
            dryLine(x: 0.65, y: 0.70, length: 0.09, angle: 18, side: side, opacity: strength)
            dryLine(x: 0.40, y: 0.74, length: 0.06, angle: -8, side: side, opacity: strength * 0.8)
            dryLine(x: 0.60, y: 0.74, length: 0.06, angle: 12, side: side, opacity: strength * 0.8)
        }
    }

    @ViewBuilder
    private func rednessLayer(scores: ScoreMap, side: CGFloat) -> some View {
        let score = scores.redness
        if score < 70 {
            let strength = BlemishIntensity.opacity(for: score)
            let positions: [(Double, Double)] = [(0.30, 0.66), (0.70, 0.66)]
            ForEach(0..<positions.count, id: \.self) { i in
                let pos = positions[i]
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                GlowbiteColors.redAlert.opacity(0.50 * strength),
                                GlowbiteColors.redAlert.opacity(0)
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: side * 0.11
                        )
                    )
                    .frame(width: side * 0.28, height: side * 0.22)
                    .blur(radius: 5)
                    .position(x: side * pos.0, y: side * pos.1)
            }
        }
    }

    @ViewBuilder
    private func darkSpotsLayer(scores: ScoreMap, side: CGFloat) -> some View {
        let score = scores.darkSpots
        if score < 70 {
            let strength = BlemishIntensity.opacity(for: score)
            darkPatch(x: 0.22, y: 0.52, w: 0.11, h: 0.08, side: side, alpha: strength)
            darkPatch(x: 0.76, y: 0.50, w: 0.09, h: 0.07, side: side, alpha: strength)
        }
    }

    @ViewBuilder
    private func acneLayer(scores: ScoreMap, side: CGFloat) -> some View {
        let score = scores.acne
        if score < 70 {
            let strength = BlemishIntensity.opacity(for: score)
            let count = BlemishIntensity.acneBumpCount(for: score)
            // Preset cluster positions — more bumps shown for worse scores.
            let positions: [(x: Double, y: Double, size: Double)] = [
                (0.30, 0.66, 0.045),
                (0.70, 0.66, 0.045),
                (0.26, 0.70, 0.038),
                (0.74, 0.70, 0.038),
                (0.36, 0.68, 0.032),
                (0.64, 0.68, 0.032),
                (0.32, 0.72, 0.030),
                (0.68, 0.72, 0.030)
            ]
            ForEach(0..<min(count, positions.count), id: \.self) { i in
                let p = positions[i]
                acneBump(x: p.x, y: p.y, size: p.size, side: side, alpha: strength)
            }
        }
    }

    @ViewBuilder
    private func textureLayer(scores: ScoreMap, side: CGFloat) -> some View {
        let score = scores.texture
        if score < 70 {
            let strength = BlemishIntensity.opacity(for: score)
            let dots: [(Double, Double)] = [
                (0.43, 0.63), (0.47, 0.65), (0.45, 0.68), (0.51, 0.63),
                (0.53, 0.67), (0.55, 0.64), (0.49, 0.69), (0.57, 0.68)
            ]
            ForEach(0..<dots.count, id: \.self) { i in
                let d = dots[i]
                Circle()
                    .fill(GlowbiteColors.warmBrown.opacity(0.32 * strength))
                    .frame(width: side * 0.009, height: side * 0.009)
                    .position(x: side * d.0, y: side * d.1)
            }
        }
    }

    @ViewBuilder
    private func poresLayer(scores: ScoreMap, side: CGFloat) -> some View {
        let score = scores.pores
        if score < 70 {
            let strength = BlemishIntensity.opacity(for: score)
            let dots: [(Double, Double)] = [
                (0.48, 0.60), (0.51, 0.61), (0.49, 0.63), (0.52, 0.64),
                (0.50, 0.65), (0.51, 0.66)
            ]
            ForEach(0..<dots.count, id: \.self) { i in
                let d = dots[i]
                Circle()
                    .fill(GlowbiteColors.darkBrown.opacity(0.45 * strength))
                    .frame(width: side * 0.005, height: side * 0.005)
                    .position(x: side * d.0, y: side * d.1)
            }
        }
    }

    @ViewBuilder
    private func wrinklesLayer(scores: ScoreMap, side: CGFloat) -> some View {
        let score = scores.wrinkles
        if score < 70 {
            let strength = BlemishIntensity.opacity(for: score)
            // Forehead lines
            thinLine(x: 0.50, y: 0.42, length: 0.28, angle: 0, side: side, opacity: 0.5 * strength)
            thinLine(x: 0.50, y: 0.46, length: 0.22, angle: 0, side: side, opacity: 0.4 * strength)
            // Eye crease hints
            thinLine(x: 0.33, y: 0.57, length: 0.08, angle: 10, side: side, opacity: 0.45 * strength)
            thinLine(x: 0.67, y: 0.57, length: 0.08, angle: -10, side: side, opacity: 0.45 * strength)
        }
    }

    @ViewBuilder
    private func elasticityLayer(scores: ScoreMap, side: CGFloat) -> some View {
        let score = scores.elasticity
        if score < 70 {
            let strength = BlemishIntensity.opacity(for: score)
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            GlowbiteColors.darkBrown.opacity(0.14 * strength),
                            GlowbiteColors.darkBrown.opacity(0)
                        ],
                        center: .top,
                        startRadius: 0,
                        endRadius: side * 0.22
                    )
                )
                .frame(width: side * 0.52, height: side * 0.10)
                .position(x: side * 0.50, y: side * 0.88)
        }
    }

    @ViewBuilder
    private func allClearGlow(scores: ScoreMap, side: CGFloat) -> some View {
        // When every per-metric score is also ≥70, add an extra glossy highlight
        // so the apple literally shines. Sparkles come from the tier layer.
        if scores.allGood {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.white.opacity(0.55), Color.white.opacity(0)],
                        center: .center,
                        startRadius: 0,
                        endRadius: side * 0.05
                    )
                )
                .frame(width: side * 0.10, height: side * 0.14)
                .rotationEffect(.degrees(-18))
                .position(x: side * 0.34, y: side * 0.42)
        }
    }

    // MARK: - Shape helpers

    private func acneBump(x: Double, y: Double, size: Double, side: CGFloat, alpha: Double) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: "F08579").opacity(alpha),
                        Color(hex: "C94A3C").opacity(alpha),
                        Color(hex: "A83428").opacity(alpha * 0.9)
                    ],
                    center: UnitPoint(x: 0.35, y: 0.30),
                    startRadius: 0,
                    endRadius: side * size * 0.6
                )
            )
            .frame(width: side * size, height: side * size)
            .position(x: side * x, y: side * y)
    }

    private func darkPatch(x: Double, y: Double, w: Double, h: Double, side: CGFloat, alpha: Double) -> some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [
                        Color(hex: "5A321E").opacity(0.55 * alpha),
                        Color(hex: "5A321E").opacity(0)
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: side * 0.05
                )
            )
            .frame(width: side * w, height: side * h)
            .blur(radius: 2)
            .position(x: side * x, y: side * y)
    }

    private func dryLine(x: Double, y: Double, length: Double, angle: Double, side: CGFloat, opacity: Double) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.55 * opacity))
            .frame(width: side * length, height: 1)
            .rotationEffect(.degrees(angle))
            .position(x: side * x, y: side * y)
    }

    private func thinLine(x: Double, y: Double, length: Double, angle: Double, side: CGFloat, opacity: Double) -> some View {
        LinearGradient(
            colors: [
                GlowbiteColors.darkBrown.opacity(0),
                GlowbiteColors.darkBrown.opacity(opacity),
                GlowbiteColors.darkBrown.opacity(0)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: side * length, height: 1)
        .rotationEffect(.degrees(angle))
        .position(x: side * x, y: side * y)
    }
}

// MARK: - Glow tier
//
// Drives the apple's overall expression (mouth, eyes, sparkles) so the character
// visibly reacts to the glow score. Per-metric blemishes still layer on top,
// so low glow + bad acne still shows the acne bumps on the cheeks.

enum GlowTier {
    case glowing    // 90-100
    case great      // 80-89
    case good       // 70-79
    case fair       // 60-69
    case needsLove  // <60

    init(glowScore: Double) {
        switch glowScore {
        case 90...: self = .glowing
        case 80..<90: self = .great
        case 70..<80: self = .good
        case 60..<70: self = .fair
        default:      self = .needsLove
        }
    }

    /// Mouth curve: +1 = big smile, 0 = flat line, -1 = full frown.
    var mouthCurve: Double {
        switch self {
        case .glowing:   return 1.0
        case .great:     return 0.7
        case .good:      return 0.45
        case .fair:      return 0.08
        case .needsLove: return -0.35
        }
    }

    /// Eye peak: +1 = happy "^ ^", 0 = flat line, -1 = droopy "v v".
    var eyePeak: Double {
        switch self {
        case .glowing:   return 1.0
        case .great:     return 0.9
        case .good:      return 0.65
        case .fair:      return 0.1
        case .needsLove: return -0.45
        }
    }

    /// Number of ambient sparkles shown around the apple.
    var sparkleCount: Int {
        switch self {
        case .glowing:   return 3
        case .great:     return 2
        case .good:      return 1
        default:         return 0
        }
    }
}

// MARK: - Apple body (matches app icon style)
//
// Drawn inside a square of `side × side`. Coordinate conventions used by the
// blemish layer above:
//   body center  ≈ (0.50, 0.57)
//   body radius  ≈ 0.42 * side
//   bite cutout  at bottom-right
//   leaf + stem  sit above the body

private struct AppleBody: View {
    let side: CGFloat
    let tier: GlowTier

    // Palette — sampled to match the app icon's apple.
    private let bodyLight = Color(hex: "FFCFB8")    // top-right highlight side
    private let bodyMid   = Color(hex: "F5A488")
    private let bodyDark  = Color(hex: "E68A6A")    // bottom-left shadow side

    private let leafGreen    = Color(hex: "66BB6A")
    private let leafDark     = Color(hex: "4A8D4E")
    private let stemBrown    = Color(hex: "4B3D36")

    private let cheekPink    = Color(hex: "F9B5A8")
    private let faceInk      = Color(hex: "2B1F1A")

    var body: some View {
        ZStack {
            // Apple body + bite cutout, filled with the icon-style gradient
            AppleBodyShape()
                .fill(
                    RadialGradient(
                        colors: [bodyLight, bodyMid, bodyDark],
                        center: UnitPoint(x: 0.70, y: 0.28),
                        startRadius: side * 0.02,
                        endRadius: side * 0.75
                    )
                )

            // Subtle inner shading on the bottom-left for depth
            AppleBodyShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0),
                            Color(hex: "C26A50").opacity(0.18)
                        ],
                        center: UnitPoint(x: 0.2, y: 0.85),
                        startRadius: 0,
                        endRadius: side * 0.60
                    )
                )
                .blendMode(.multiply)

            // Stem (sits behind the leaf, so draw first)
            Ellipse()
                .fill(stemBrown)
                .frame(width: side * 0.07, height: side * 0.09)
                .rotationEffect(.degrees(-12))
                .position(x: side * 0.47, y: side * 0.18)

            // Leaf
            LeafShape()
                .fill(
                    LinearGradient(
                        colors: [leafGreen, leafDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: side * 0.22, height: side * 0.14)
                .rotationEffect(.degrees(18))
                .position(x: side * 0.58, y: side * 0.17)

            // Main glossy highlight (big curved oval, top-left-of-center)
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.95),
                            Color.white.opacity(0.55)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: side * 0.09, height: side * 0.22)
                .rotationEffect(.degrees(-18))
                .position(x: side * 0.37, y: side * 0.44)

            // Small highlight above the main one
            Ellipse()
                .fill(Color.white.opacity(0.85))
                .frame(width: side * 0.05, height: side * 0.055)
                .position(x: side * 0.32, y: side * 0.36)

            // Cheeks
            Ellipse()
                .fill(cheekPink.opacity(0.75))
                .frame(width: side * 0.11, height: side * 0.055)
                .position(x: side * 0.34, y: side * 0.66)
            Ellipse()
                .fill(cheekPink.opacity(0.75))
                .frame(width: side * 0.11, height: side * 0.055)
                .position(x: side * 0.66, y: side * 0.66)

            // Eyes — peak amount shifts with glow tier (happy → flat → droopy)
            HappyEyeShape(peak: tier.eyePeak)
                .stroke(faceInk, style: StrokeStyle(lineWidth: side * 0.018, lineCap: .round, lineJoin: .round))
                .frame(width: side * 0.11, height: side * 0.055)
                .position(x: side * 0.37, y: side * 0.57)
            HappyEyeShape(peak: tier.eyePeak)
                .stroke(faceInk, style: StrokeStyle(lineWidth: side * 0.018, lineCap: .round, lineJoin: .round))
                .frame(width: side * 0.11, height: side * 0.055)
                .position(x: side * 0.63, y: side * 0.57)

            // Mouth — curve shifts with glow tier (smile → flat → frown)
            SmileShape(curve: tier.mouthCurve)
                .stroke(faceInk, style: StrokeStyle(lineWidth: side * 0.018, lineCap: .round, lineJoin: .round))
                .frame(width: side * 0.11, height: side * 0.04)
                .position(x: side * 0.50, y: side * 0.73)

            // Ambient sparkles for higher tiers
            tierSparkles
        }
        .frame(width: side, height: side)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: tier.mouthCurve)
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: tier.eyePeak)
    }

    @ViewBuilder
    private var tierSparkles: some View {
        let count = tier.sparkleCount
        if count >= 1 {
            Text("✨")
                .font(.system(size: side * 0.08))
                .position(x: side * 0.94, y: side * 0.42)
        }
        if count >= 2 {
            Text("✨")
                .font(.system(size: side * 0.06))
                .position(x: side * 0.06, y: side * 0.60)
        }
        if count >= 3 {
            Text("✨")
                .font(.system(size: side * 0.05))
                .position(x: side * 0.15, y: side * 0.22)
        }
    }
}

// MARK: - Apple body shape (circle minus bite)

private struct AppleBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)

        // Main body circle, centered in the lower ~80% of the square so the
        // leaf + stem can sit above it.
        let bodyDiameter = side * 0.82
        let bodyRect = CGRect(
            x: rect.midX - bodyDiameter / 2,
            y: side * 0.22,
            width: bodyDiameter,
            height: bodyDiameter
        )
        var body = Path()
        body.addEllipse(in: bodyRect)

        // Bite cutout on the bottom-right
        let biteDiameter = side * 0.24
        let biteRect = CGRect(
            x: bodyRect.maxX - biteDiameter * 0.65,
            y: bodyRect.maxY - biteDiameter * 1.15,
            width: biteDiameter,
            height: biteDiameter
        )
        var bite = Path()
        bite.addEllipse(in: biteRect)

        return body.subtracting(bite)
    }
}

// MARK: - Leaf shape

private struct LeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Rounded teardrop pointing up-right
        path.move(to: CGPoint(x: 0, y: h * 0.55))
        path.addQuadCurve(
            to: CGPoint(x: w, y: h * 0.4),
            control: CGPoint(x: w * 0.45, y: -h * 0.2)
        )
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.55),
            control: CGPoint(x: w * 0.55, y: h * 1.1)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Happy eye
//
// peak = +1 → "^" (closed happy eyes, like the app icon)
// peak =  0 → "−" (flat line, neutral)
// peak = -1 → "v" (droopy tired eyes)

private struct HappyEyeShape: Shape {
    /// -1..+1. Animatable.
    var peak: Double

    var animatableData: Double {
        get { peak }
        set { peak = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Endpoints slide vertically so a flat line (peak=0) isn't pinned at
        // the bottom; droopy eyes (peak<0) dip below the midline.
        let endY = h * (0.5 + 0.5 * peak)
        let ctrlY = h * (0.5 - peak)   // opposite direction from endpoints
        path.move(to: CGPoint(x: 0, y: endY))
        path.addQuadCurve(
            to: CGPoint(x: w, y: endY),
            control: CGPoint(x: w / 2, y: ctrlY)
        )
        return path
    }
}

// MARK: - Smile
//
// curve = +1 → big upturned smile
// curve =  0 → flat line
// curve = -1 → frown

private struct SmileShape: Shape {
    /// -1..+1. Animatable.
    var curve: Double

    var animatableData: Double {
        get { curve }
        set { curve = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        // Endpoints sit at a mid-baseline so a frown curves below it.
        let baseY = h * 0.5
        let ctrlY = baseY + h * 1.1 * curve
        path.move(to: CGPoint(x: 0, y: baseY))
        path.addQuadCurve(
            to: CGPoint(x: w, y: baseY),
            control: CGPoint(x: w / 2, y: ctrlY)
        )
        return path
    }
}

// MARK: - Score map

/// Turns `SkinScan.metrics` into direct property lookups so the blemish layer
/// doesn't filter the array every frame.
private struct ScoreMap {
    let hydration: Double
    let acne: Double
    let texture: Double
    let elasticity: Double
    let darkSpots: Double
    let redness: Double
    let pores: Double
    let wrinkles: Double

    init(metrics: [SkinMetric]) {
        var h = 100.0, a = 100.0, t = 100.0, e = 100.0
        var ds = 100.0, r = 100.0, p = 100.0, w = 100.0
        for m in metrics {
            switch m.type {
            case .hydration:   h = m.score
            case .acne:        a = m.score
            case .texture:     t = m.score
            case .elasticity:  e = m.score
            case .darkSpots:   ds = m.score
            case .redness:     r = m.score
            case .pores:       p = m.score
            case .wrinkles:    w = m.score
            }
        }
        self.hydration = h
        self.acne = a
        self.texture = t
        self.elasticity = e
        self.darkSpots = ds
        self.redness = r
        self.pores = p
        self.wrinkles = w
    }

    var allGood: Bool {
        [hydration, acne, texture, elasticity, darkSpots, redness, pores, wrinkles]
            .allSatisfy { $0 >= 70 }
    }
}

// MARK: - Severity → visual intensity

private enum BlemishIntensity {
    /// 0..1 multiplier for blemish opacity based on metric score.
    /// ≥70 → 0 (invisible), 25 → ~0.85, 0 → 1.0.
    static func opacity(for score: Double) -> Double {
        switch score {
        case 70...: return 0
        case 55..<70: return 0.38
        case 40..<55: return 0.62
        case 25..<40: return 0.85
        default: return 1.0
        }
    }

    static func acneBumpCount(for score: Double) -> Int {
        switch score {
        case 70...: return 0
        case 55..<70: return 3
        case 40..<55: return 5
        case 25..<40: return 7
        default: return 8
        }
    }
}

#if DEBUG
private func mockScan(glow: Double, metric: Double) -> SkinScan {
    SkinScan(
        glowScore: glow,
        metrics: SkinMetricType.allCases.map { SkinMetric(type: $0, score: metric) }
    )
}

#Preview("5 tiers — side by side") {
    VStack(spacing: 16) {
        ForEach(
            [
                ("Glowing 95", mockScan(glow: 95, metric: 92)),
                ("Great 85",   mockScan(glow: 85, metric: 82)),
                ("Good 75",    mockScan(glow: 75, metric: 72)),
                ("Fair 65",    mockScan(glow: 65, metric: 60)),
                ("Needs 45",   mockScan(glow: 45, metric: 38))
            ],
            id: \.0
        ) { label, scan in
            HStack(spacing: 16) {
                AppleMascotView(scan: scan)
                    .frame(width: 110, height: 110)
                Text(label)
                    .font(.custom("Nunito-Bold", size: 18))
            }
        }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(GlowbiteColors.creamBG)
}
#endif
