import SwiftUI

/// Compact Glowbite brand icon — the same coral apple silhouette as the full
/// mascot but with **no facial features**, sized for logo/wordmark use.
///
/// Rendered entirely in SwiftUI so it always has a transparent background
/// and scales crisp at any size. Use next to `GlowbiteWordmark` via
/// `GlowbiteLockup`, or solo as a nav-bar / launch mark.
struct GlowbiteIcon: View {
    /// Edge length of the icon's square frame in points. Typical values:
    /// - 24pt for toolbar / tab bar
    /// - 32-40pt for inline home-header lockups (default)
    /// - 64pt+ for hero splash / onboarding
    var size: CGFloat = 36

    // Palette — sampled to match the app icon.
    private let bodyLight = Color(hex: "FFCFB8")
    private let bodyMid   = Color(hex: "F5A488")
    private let bodyDark  = Color(hex: "E68A6A")
    private let leafGreen = Color(hex: "66BB6A")
    private let leafDark  = Color(hex: "4A8D4E")
    private let stemBrown = Color(hex: "4B3D36")

    var body: some View {
        ZStack {
            // Apple body + bite cutout
            AppleSilhouetteShape()
                .fill(
                    RadialGradient(
                        colors: [bodyLight, bodyMid, bodyDark],
                        center: UnitPoint(x: 0.70, y: 0.28),
                        startRadius: size * 0.02,
                        endRadius: size * 0.75
                    )
                )

            // Subtle bottom-left shadow for depth (muted at small sizes)
            AppleSilhouetteShape()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.black.opacity(0),
                            Color(hex: "C26A50").opacity(0.18)
                        ],
                        center: UnitPoint(x: 0.2, y: 0.85),
                        startRadius: 0,
                        endRadius: size * 0.60
                    )
                )
                .blendMode(.multiply)

            // Stem (behind leaf)
            Capsule()
                .fill(stemBrown)
                .frame(width: size * 0.06, height: size * 0.10)
                .rotationEffect(.degrees(-12))
                .position(x: size * 0.47, y: size * 0.18)

            // Leaf
            LogoLeafShape()
                .fill(
                    LinearGradient(
                        colors: [leafGreen, leafDark],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size * 0.26, height: size * 0.16)
                .rotationEffect(.degrees(18))
                .position(x: size * 0.60, y: size * 0.16)

            // Glossy highlight
            Ellipse()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.92),
                            Color.white.opacity(0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: size * 0.09, height: size * 0.22)
                .rotationEffect(.degrees(-18))
                .position(x: size * 0.36, y: size * 0.45)
        }
        .frame(width: size, height: size)
        // Do not use `.drawingGroup()` here: it rasterizes strictly to this
        // frame and clips the leaf + stem, which intentionally extend slightly
        // past the square for a natural silhouette.
    }
}

// MARK: - Shapes

private struct AppleSilhouetteShape: Shape {
    func path(in rect: CGRect) -> Path {
        let side = min(rect.width, rect.height)
        let bodyDiameter = side * 0.82
        let bodyRect = CGRect(
            x: rect.midX - bodyDiameter / 2,
            y: side * 0.22,
            width: bodyDiameter,
            height: bodyDiameter
        )
        var body = Path()
        body.addEllipse(in: bodyRect)

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

private struct LogoLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
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

#if DEBUG
#Preview {
    HStack(spacing: 24) {
        GlowbiteIcon(size: 24)
        GlowbiteIcon(size: 36)
        GlowbiteIcon(size: 56)
        GlowbiteIcon(size: 96)
    }
    .padding()
    .background(GlowbiteColors.creamBG)
}
#endif
