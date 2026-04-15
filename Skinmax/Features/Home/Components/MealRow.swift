import SwiftUI

struct MealRow: View {
    let foodScan: FoodScan

    private var dotColor: Color {
        switch foodScan.skinImpactScore {
        case 7...10: return GlowbiteColors.greenGood
        case 4..<7: return GlowbiteColors.amberFair
        default: return GlowbiteColors.redAlert
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 9)
                .fill(GlowbiteColors.softTan)
                .frame(width: 36, height: 36)
                .overlay(
                    Text("🍽")
                        .font(.system(size: 16))
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 5) {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 5, height: 5)

                    Text(foodScan.name)
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                }

                Text("\(foodScan.calories) cal · \(foodScan.createdAt.formatted(date: .omitted, time: .shortened))")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }

            Spacer()

            Text(String(format: "%.1f", foodScan.skinImpactScore))
                .font(.gbTitleL)
                .tracking(-0.3)
                .foregroundStyle(dotColor)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(GlowbiteColors.paper)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(GlowbiteColors.border, lineWidth: 1)
        )
    }
}
