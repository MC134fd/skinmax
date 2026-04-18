import SwiftUI

/// Complete Glowbite brand lockup — apple icon on the left, "Glowbite"
/// wordmark on the right. Use this in place of the old greeting header on
/// the home screen, splash screens, share cards, etc.
///
/// The lockup composes `GlowbiteIcon` and `GlowbiteWordmark` with a tuned
/// gap between them. Switch the entire brand typography app-wide by changing
/// one `variant` value here (or at the call site).
struct GlowbiteLockup: View {
    /// Font variant for the wordmark. Defaults to `.caveat` (current pick).
    var variant: GlowbiteFontVariant = .caveat
    /// Diameter of the apple icon in points.
    var iconSize: CGFloat = 32
    /// Horizontal gap between icon and wordmark.
    var gap: CGFloat = 8
    /// Override wordmark point size. `nil` uses each variant's `defaultSize`
    /// scaled for `iconSize` (36pt icon = baseline for those defaults).
    var wordmarkSize: CGFloat? = nil
    /// Wordmark color override.
    var wordmarkColor: Color = GlowbiteColors.darkBrown

    private var resolvedWordmarkSize: CGFloat {
        if let wordmarkSize { return wordmarkSize }
        let baselineIcon: CGFloat = 36
        return variant.defaultSize * (iconSize / baselineIcon)
    }

    var body: some View {
        HStack(alignment: .center, spacing: gap) {
            GlowbiteIcon(size: iconSize)
            GlowbiteWordmark(variant: variant, size: resolvedWordmarkSize, color: wordmarkColor)
        }
        // Intrinsic size so Caveat ascenders/descenders aren't clipped by the row.
        .fixedSize(horizontal: true, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Glowbite")
    }
}

#if DEBUG
#Preview("Lockup — all variants") {
    ScrollView {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(GlowbiteFontVariant.allCases) { v in
                VStack(alignment: .leading, spacing: 4) {
                    Text(v.displayName)
                        .font(.custom("Nunito-Bold", size: 11))
                        .tracking(1.5)
                        .foregroundStyle(GlowbiteColors.mediumTaupe)
                    GlowbiteLockup(variant: v)
                        .padding(.vertical, 6)
                }
            }
        }
        .padding()
    }
    .background(GlowbiteColors.creamBG)
}
#endif
