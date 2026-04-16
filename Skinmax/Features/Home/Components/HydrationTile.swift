import SwiftUI

struct HydrationTile: View {
    let consumed: Double
    let goal: Double
    let glasses: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("💧 WATER")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.hydrationBlue)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%.1f", consumed))
                    .font(.gbTitleL)
                    .tracking(-0.3)
                    .foregroundStyle(GlowbiteColors.hydrationBlue)

                Text("/ \(String(format: "%.1f", goal))L")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.hydrationBlue.opacity(0.70))
            }

            HStack(spacing: 2) {
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index < glasses ? GlowbiteColors.hydrationBlue : GlowbiteColors.hydrationBlue.opacity(0.20))
                        .frame(height: 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(GlowbiteColors.blueLight)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(GlowbiteColors.hydrationBlue.opacity(0.20), lineWidth: 1)
        )
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 6, x: 0, y: 2)
    }
}
