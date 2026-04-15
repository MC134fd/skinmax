import SwiftUI

struct FoodRowView: View {
    let foodScan: FoodScan

    private var scoreColor: Color {
        switch foodScan.skinImpactScore {
        case 8...10: return GlowbiteColors.greenGood
        case 5..<8: return GlowbiteColors.amberFair
        default: return GlowbiteColors.redAlert
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(GlowbiteColors.peachWash)
                .frame(width: 48, height: 48)
                .overlay(
                    Text("\u{1F37D}")
                        .font(.system(size: 18))
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(foodScan.name)
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Text("\(foodScan.calories) cal · \(String(format: "%.0fg", foodScan.protein)) protein")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)

                Text(foodScan.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.gbOverline)
                    .tracking(2.0)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }

            Spacer()

            // Score
            Text(String(format: "%.1f", foodScan.skinImpactScore))
                .font(.gbBodyL)
                .foregroundStyle(scoreColor)
        }
        .padding(14)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }
}
