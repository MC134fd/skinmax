import SwiftUI

struct SkinNutrientCard: View {
    let label: String
    let value: String
    let target: String
    let descriptor: String
    let color: Color
    let lightColor: Color
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(color)

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.gbTitleM)
                    .foregroundStyle(color)

                Text("/\(target)")
                    .font(.gbCaption)
                    .foregroundStyle(color.opacity(0.70))
            }

            Text(descriptor)
                .font(.gbOverline)
                .foregroundStyle(color.opacity(0.80))

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(GlowbiteColors.border)
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 3)
                }
            }
            .frame(height: 3)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 11)
        .frame(width: 90)
        .background(lightColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
