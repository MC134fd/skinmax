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
                .frame(width: 40, height: 40)
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
                    .font(SkinmaxFonts.caption())
                    .foregroundStyle(SkinmaxColors.mutedTan)

                Text(foodScan.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(SkinmaxFonts.small())
                    .foregroundStyle(SkinmaxColors.mutedTan)
            }

            Spacer()

            // Score
            Text(String(format: "%.1f", foodScan.skinImpactScore))
                .font(.custom("Nunito-SemiBold", size: 16))
                .foregroundStyle(scoreColor)
        }
        .padding(14)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}
