import SwiftUI
import UIKit

/// Glowbite wordmark — the "Glowbite" lettering portion of the brand lockup.
///
/// Eight font variants are bundled. Swap between them by changing the
/// `.variant` argument. See `Skinmax/Core/Design/Branding/README.md` for how
/// to preview and pick a variant.
///
/// Usage:
/// ```swift
/// GlowbiteWordmark()                           // defaults to .caveat
/// GlowbiteWordmark(variant: .fraunces, size: 34)
/// ```
///
/// The view has no background — it draws only glyphs, so it sits transparently
/// on top of any screen background.
///
/// **Implementation note:** The wordmark is backed by `UILabel`, not SwiftUI
/// `Text`. Script faces like Caveat draw ink that extends past Core Text's
/// tight layout bounds; `Text` clips those tails, while `UILabel` with
/// `clipsToBounds = false` paints the full glyph.
struct GlowbiteWordmark: View {
    var variant: GlowbiteFontVariant = .caveat
    /// Optical size in points. Each variant has its own default tuned to
    /// match the others visually, so you usually don't need to set this.
    var size: CGFloat? = nil
    var color: Color = GlowbiteColors.darkBrown

    var body: some View {
        GlowbiteWordmarkRepresentable(
            variant: variant,
            pointSize: size ?? variant.defaultSize,
            color: color
        )
        .fixedSize(horizontal: true, vertical: true)
        // Layout margin so script tails aren’t flush against the next sibling
        // (narrow screens + HStack can otherwise clip the last pixel column).
        .padding(.trailing, 4)
    }
}

// MARK: - UIKit bridge (avoids SwiftUI Text clipping script overshoot)

private struct GlowbiteWordmarkRepresentable: UIViewRepresentable {
    let variant: GlowbiteFontVariant
    let pointSize: CGFloat
    let color: Color

    func makeUIView(context: Context) -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byClipping
        label.clipsToBounds = false
        label.backgroundColor = .clear
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .vertical)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    func updateUIView(_ label: UILabel, context: Context) {
        let font = variant.uiFont(size: pointSize)
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor(color),
            .kern: variant.tracking
        ]
        label.attributedText = NSAttributedString(string: "Glowbite", attributes: attrs)
    }
}

// MARK: - Variants

enum GlowbiteFontVariant: String, CaseIterable, Identifiable {
    /// 01 — Nunito Black. Matches the rest of the app's Nunito type system.
    case nunito
    /// 02 — Fraunces ExtraBold (9pt Black instance). Warm editorial serif.
    case fraunces
    /// 03 — Instrument Serif Italic. Thin, luxury-magazine feel.
    case instrumentSerif
    /// 04 — DM Serif Display. Bold chunky serif.
    case dmSerif
    /// 05 — Playfair Display Black Italic. High-contrast fashion-editorial.
    case playfair
    /// 06 — Space Grotesk Bold. Clean modern geometric.
    case spaceGrotesk
    /// 07 — Unbounded Black. Quirky display display sans.
    case unbounded
    /// 08 — Caveat Bold. Handwritten, BFF voice. Current production pick.
    case caveat

    var id: String { rawValue }

    /// Human-friendly label used in the variant picker preview.
    var displayName: String {
        switch self {
        case .nunito:          return "Nunito Black"
        case .fraunces:        return "Fraunces ExtraBold"
        case .instrumentSerif: return "Instrument Serif Italic"
        case .dmSerif:         return "DM Serif Display"
        case .playfair:        return "Playfair Display Black Italic"
        case .spaceGrotesk:    return "Space Grotesk Bold"
        case .unbounded:       return "Unbounded Black"
        case .caveat:          return "Caveat Bold"
        }
    }

    /// PostScript name of the bundled .ttf. For variable fonts we reference
    /// the default instance and shape it with `.weight()` in `font(size:)`.
    fileprivate var postScriptName: String {
        switch self {
        case .nunito:          return "Nunito-Black"
        case .fraunces:        return "Fraunces-9ptBlack"
        case .instrumentSerif: return "InstrumentSerif-Italic"
        case .dmSerif:         return "DMSerifDisplay-Regular"
        case .playfair:        return "PlayfairDisplay-Italic"
        case .spaceGrotesk:    return "SpaceGrotesk-Light"
        case .unbounded:       return "Unbounded-Regular"
        case .caveat:          return "Caveat-Regular"
        }
    }

    /// Per-variant default optical size so that all 8 variants look balanced
    /// when placed next to the same icon. Tuned against a 36pt apple icon.
    var defaultSize: CGFloat {
        switch self {
        case .nunito:          return 30
        case .fraunces:        return 30
        case .instrumentSerif: return 36
        case .dmSerif:         return 34
        case .playfair:        return 30
        case .spaceGrotesk:    return 28
        case .unbounded:       return 24
        case .caveat:          return 42
        }
    }

    /// Per-variant letter-spacing. Negative tightens; positive loosens.
    var tracking: CGFloat {
        switch self {
        case .nunito:          return -1.0
        case .fraunces:        return -0.8
        case .instrumentSerif: return -0.4
        case .dmSerif:         return -0.6
        case .playfair:        return -0.8
        case .spaceGrotesk:    return -1.2
        case .unbounded:       return -0.8
        case .caveat:          return 0
        }
    }

    /// Resolves the bundled font for UIKit. Keeps variable-font weights in
    /// sync with the former SwiftUI `Font.custom(...).weight(...)` mapping.
    fileprivate func uiFont(size: CGFloat) -> UIFont {
        guard let base = UIFont(name: postScriptName, size: size) else {
            return .systemFont(ofSize: size, weight: .bold)
        }
        switch self {
        case .playfair:
            let traits: UIFontDescriptor.SymbolicTraits = [.traitBold, .traitItalic]
            guard let desc = base.fontDescriptor.withSymbolicTraits(traits) else { return base }
            return UIFont(descriptor: desc, size: size)
        case .spaceGrotesk, .unbounded, .caveat:
            guard let desc = base.fontDescriptor.withSymbolicTraits(.traitBold) else { return base }
            return UIFont(descriptor: desc, size: size)
        case .nunito, .fraunces, .instrumentSerif, .dmSerif:
            return base
        }
    }
}

// MARK: - Preview harness

#if DEBUG
#Preview("All 8 variants") {
    ScrollView {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(GlowbiteFontVariant.allCases) { variant in
                VStack(alignment: .leading, spacing: 6) {
                    Text(variant.displayName.uppercased())
                        .font(.custom("Nunito-Bold", size: 11))
                        .tracking(2)
                        .foregroundStyle(GlowbiteColors.mediumTaupe)
                    HStack(spacing: 10) {
                        GlowbiteIcon(size: 36)
                        GlowbiteWordmark(variant: variant)
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(GlowbiteColors.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: GlowbiteColors.cardShadowColor, radius: 8, x: 0, y: 2)
                }
            }
        }
        .padding()
    }
    .background(GlowbiteColors.creamBG)
}

#Preview("Caveat · production") {
    HStack(spacing: 10) {
        GlowbiteIcon(size: 36)
        GlowbiteWordmark(variant: .caveat)
    }
    .padding()
    .background(GlowbiteColors.creamBG)
}
#endif
