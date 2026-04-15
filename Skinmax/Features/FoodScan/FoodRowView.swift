import SwiftUI

struct FoodRowView: View {
    let foodScan: FoodScan

    private var scoreColor: Color {
        switch foodScan.skinImpactScore {
        case 8...10: return SkinmaxColors.greenGood
        case 5..<8: return SkinmaxColors.amberFair
        default: return SkinmaxColors.redAlert
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 10)
                .fill(SkinmaxColors.peachWash)
                .frame(width: 48, height: 48)
                .overlay(
                    Text("\u{1F37D}")
                        .font(.system(size: 18))
                )

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(foodScan.name)
                    .font(SkinmaxFonts.h3())
                    .foregroundStyle(SkinmaxColors.darkBrown)

                Text("\(foodScan.calories) cal · \(String(format: "%.0fg", foodScan.protein)) protein")
                    .font(.gbCaption)
                    .foregroundStyle(SkinmaxColors.lightTaupe)

                Text(foodScan.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.gbOverline)
                    .foregroundStyle(SkinmaxColors.lightTaupe)
            }

            Spacer()

            // Score
            Text(String(format: "%.1f", foodScan.skinImpactScore))
                .font(.gbBodyL)
                .foregroundStyle(scoreColor)
        }
        .padding(14)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)
    }
}
