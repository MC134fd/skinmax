import SwiftUI

struct SkinNutrientCard: View {
    let label: String
    let value: String
    let target: String
    let descriptor: String
    let signatureColor: Color
    let signatureLightColor: Color
    let barColor: Color
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(signatureColor)

            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.gbTitleM)
                    .foregroundStyle(signatureColor)

                Text("/\(target)")
                    .font(.gbCaption)
                    .foregroundStyle(signatureColor.opacity(0.55))
            }

            Text(descriptor)
                .font(.gbOverline)
                .foregroundStyle(signatureColor.opacity(0.65))

            Spacer()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(signatureColor.opacity(0.12))
                        .frame(height: 3)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor)
                        .frame(width: geo.size.width * min(progress, 1.0), height: 3)
                        .animation(.easeOut(duration: 0.6), value: progress)
                }
            }
            .frame(height: 3)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(signatureLightColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
