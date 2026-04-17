import SwiftUI

struct CalorieRingCard: View {
    let consumed: Int
    let goal: Int

    private var remaining: Int { max(goal - consumed, 0) }
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(consumed) / Double(goal), 1.0)
    }

    @State private var animatedProgress: Double = 0

    var body: some View {
        ZStack {
            Circle()
                .stroke(GlowbiteColors.softTan, lineWidth: 10)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    GlowbiteColors.darkBrown,
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .frame(width: 160, height: 160)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("CALORIES LEFT")
                    .font(.gbOverline)
                    .tracking(1.5)
                    .foregroundStyle(GlowbiteColors.lightTaupe)

                Text("\(remaining)")
                    .font(.gbDisplayL)
                    .tracking(-1.0)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Text("kcal")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(GlowbiteColors.paper)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius)
                .stroke(GlowbiteColors.border, lineWidth: 1)
        )
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 6, x: 0, y: 2)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75)) {
                animatedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75)) {
                animatedProgress = newValue
            }
        }
    }
}
