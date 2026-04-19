import SwiftUI

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = GlowbiteSpacing.cardCornerRadius

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white.opacity(0.72))
                    .background(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.65), lineWidth: 1)
            )
            .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = GlowbiteSpacing.cardCornerRadius) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
