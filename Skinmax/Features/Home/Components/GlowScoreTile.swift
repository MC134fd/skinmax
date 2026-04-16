import SwiftUI

struct GlowScoreTile: View {
    let scan: SkinScan?
    let trendDiff: Int?

    private var score: Double { scan?.glowScore ?? 0 }

    private var bucketLabel: String {
        guard scan != nil else { return "Scan to start" }
        switch score {
        case 90...100: return "Glowing"
        case 75..<90: return "Great"
        case 60..<75: return "Good"
        case 40..<60: return "Fair"
        default: return "Low"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("✦ GLOW")
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.lightTaupe)

            if let scan {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.0f", scan.glowScore))
                        .font(.gbDisplayM)
                        .tracking(-0.5)
                        .foregroundStyle(GlowbiteColors.creamBG)

                    if let diff = trendDiff, diff != 0 {
                        Text("\(diff > 0 ? "↑" : "↓")\(abs(diff))")
                            .font(.gbCaption)
                            .foregroundStyle(GlowbiteColors.greenGood)
                    }
                }
            } else {
                Text("—")
                    .font(.gbDisplayM)
                    .tracking(-0.5)
                    .foregroundStyle(GlowbiteColors.creamBG)
            }

            Text(bucketLabel)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.lightTaupe)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(12)
        .background(
            ZStack(alignment: .topTrailing) {
                GlowbiteColors.darkBrown

                Circle()
                    .fill(GlowbiteColors.coral.opacity(0.25))
                    .frame(width: 60, height: 60)
                    .blur(radius: 16)
                    .offset(x: 10, y: -10)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 6, x: 0, y: 2)
    }
}
