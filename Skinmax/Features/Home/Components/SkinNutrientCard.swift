import SwiftUI

struct SkinNutrientCard: View {
    let label: String
    let remainingText: String
    let statusLabel: String
    let isOver: Bool
    let descriptor: String
    let signatureColor: Color
    let signatureLightColor: Color
    let barColor: Color
    let progress: Double

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.gbOverline)
                    .tracking(2.0)
                    .foregroundStyle(signatureColor)
                Spacer()
            }

            Spacer()

            ZStack {
                Circle()
                    .stroke(signatureColor.opacity(0.15), lineWidth: 5.5)

                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(barColor, style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 0.6), value: progress)

                Text(remainingText)
                    .font(.gbDisplayM)
                    .foregroundStyle(isOver ? GlowbiteColors.redAlert : signatureColor)
            }
            .frame(width: 72, height: 72)

            Text(statusLabel)
                .font(.gbCaption)
                .foregroundStyle(isOver ? GlowbiteColors.redAlert.opacity(0.7) : signatureColor.opacity(0.55))
                .padding(.top, 2)

            Spacer()

            HStack {
                Text(descriptor)
                    .font(.gbOverline)
                    .foregroundStyle(signatureColor.opacity(0.65))
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(signatureLightColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 6, x: 0, y: 2)
    }
}
