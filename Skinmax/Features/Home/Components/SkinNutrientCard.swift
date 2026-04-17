import SwiftUI

struct SkinNutrientCard: View {
    let label: String
    let remainingWithUnit: String
    let statusWord: String
    let isOver: Bool
    let descriptor: String
    let signatureColor: Color
    let signatureLightColor: Color
    let barColor: Color
    let progress: Double

    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(spacing: 0) {
            Text(label)
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(signatureColor)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            ZStack {
                Circle()
                    .stroke(signatureColor.opacity(0.15), lineWidth: 5.5)

                Circle()
                    .trim(from: 0, to: min(animatedProgress, 1.0))
                    .stroke(barColor, style: StrokeStyle(lineWidth: 5.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text(remainingWithUnit)
                        .font(.gbTitleM)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)

                    Text(statusWord)
                        .font(.gbOverline)
                        .lineLimit(1)
                }
                .foregroundStyle(isOver ? GlowbiteColors.redAlert : signatureColor)
                .padding(.horizontal, 6)
            }
            .frame(width: 72, height: 72)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7)) {
                    animatedProgress = progress
                }
            }
            .onChange(of: progress) { _, newValue in
                withAnimation(.easeOut(duration: 0.5)) {
                    animatedProgress = newValue
                }
            }

            Spacer()

            Text(descriptor)
                .font(.gbOverline)
                .foregroundStyle(signatureColor.opacity(0.65))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(signatureLightColor)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 6, x: 0, y: 2)
    }
}
