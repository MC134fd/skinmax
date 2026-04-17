import SwiftUI

struct WaterDropletShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let midX = rect.midX

        path.move(to: CGPoint(x: midX, y: rect.minY))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + h * 0.66),
            control1: CGPoint(x: midX + w * 0.02, y: rect.minY + h * 0.24),
            control2: CGPoint(x: rect.maxX, y: rect.minY + h * 0.42)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: rect.maxY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + h * 0.90),
            control2: CGPoint(x: midX + w * 0.32, y: rect.maxY)
        )
        path.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + h * 0.66),
            control1: CGPoint(x: midX - w * 0.32, y: rect.maxY),
            control2: CGPoint(x: rect.minX, y: rect.minY + h * 0.90)
        )
        path.addCurve(
            to: CGPoint(x: midX, y: rect.minY),
            control1: CGPoint(x: rect.minX, y: rect.minY + h * 0.42),
            control2: CGPoint(x: midX - w * 0.02, y: rect.minY + h * 0.24)
        )
        path.closeSubpath()
        return path
    }
}

struct WaterDropletVisualizer: View {
    let fillRatio: Double
    let centerNumber: String
    let unitLabel: String
    let subtitle: String

    private var clampedRatio: Double {
        min(max(fillRatio, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                WaterDropletShape()
                    .fill(GlowbiteColors.hydrationBlue.opacity(0.10))

                WaterDropletShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                GlowbiteColors.hydrationBlue.opacity(0.85),
                                GlowbiteColors.hydrationBlue
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .mask(
                        Rectangle()
                            .frame(
                                width: geo.size.width,
                                height: geo.size.height * clampedRatio
                            )
                            .frame(
                                width: geo.size.width,
                                height: geo.size.height,
                                alignment: .bottom
                            )
                            .animation(
                                .spring(response: 0.9, dampingFraction: 0.72),
                                value: clampedRatio
                            )
                    )

                WaterDropletShape()
                    .stroke(GlowbiteColors.hydrationBlue.opacity(0.55), lineWidth: 2)

                VStack(spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(centerNumber)
                            .font(.gbDisplayM)
                            .tracking(-0.5)
                            .foregroundStyle(clampedRatio > 0.35 ? .white : GlowbiteColors.hydrationBlue)

                        Text(unitLabel)
                            .font(.gbCaption)
                            .foregroundStyle(
                                (clampedRatio > 0.35 ? Color.white : GlowbiteColors.hydrationBlue)
                                    .opacity(0.85)
                            )
                    }

                    Text(subtitle)
                        .font(.gbOverline)
                        .tracking(1.2)
                        .foregroundStyle(
                            (clampedRatio > 0.35 ? Color.white : GlowbiteColors.hydrationBlue)
                                .opacity(0.75)
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

#if DEBUG
#Preview("Water Droplet — 0%") {
    WaterDropletVisualizer(fillRatio: 0, centerNumber: "0", unitLabel: "ML", subtitle: "0% of goal")
        .frame(width: 160, height: 200)
        .padding(40)
        .background(GlowbiteColors.creamBG)
}

#Preview("Water Droplet — 38%") {
    WaterDropletVisualizer(fillRatio: 0.38, centerNumber: "750", unitLabel: "ML", subtitle: "38% of goal")
        .frame(width: 160, height: 200)
        .padding(40)
        .background(GlowbiteColors.creamBG)
}

#Preview("Water Droplet — 100%") {
    WaterDropletVisualizer(fillRatio: 1.0, centerNumber: "2,000", unitLabel: "ML", subtitle: "Goal hit! 🎉")
        .frame(width: 160, height: 200)
        .padding(40)
        .background(GlowbiteColors.creamBG)
}
#endif
