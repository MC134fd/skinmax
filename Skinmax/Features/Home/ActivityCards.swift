import SwiftUI

// MARK: - Face Scan Illustration Selector

enum FaceIllustrationSelector {
    static func assetName(for scan: SkinScan) -> String {
        guard let worstMetric = scan.metrics.min(by: { $0.score < $1.score }) else {
            return "face-default"
        }
        let tier = tierName(for: worstMetric.score)
        let key = metricKey(for: worstMetric.type)
        return "\(key)-\(tier)"
    }

    private static func tierName(for score: Double) -> String {
        switch score {
        case 70...100: return "good"
        case 40..<70: return "fair"
        default: return "poor"
        }
    }

    private static func metricKey(for type: SkinMetricType) -> String {
        switch type {
        case .darkSpots: return "darkspots"
        default: return type.rawValue
        }
    }
}

// MARK: - Face Activity Card (Premium/Editorial)

struct FaceActivityCard: View {
    let scan: SkinScan
    let onTap: () -> Void

    private var topMetrics: [SkinMetric] {
        Array(scan.metrics.sorted { $0.score < $1.score }.prefix(3))
    }

    private var illustrationName: String {
        FaceIllustrationSelector.assetName(for: scan)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                ZStack {
                    GlowbiteColors.heroGradient

                    if let img = UIImage(named: illustrationName) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else if let img = UIImage(named: "face-default") {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text(topMetrics.first?.type.icon ?? "\u{1F9D1}")
                            .font(.gbDisplayL)
                            .tracking(-1.0)
                    }
                }
                .frame(width: 90)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text("FACE SCAN")
                        .font(.gbOverline)
                        .foregroundStyle(GlowbiteColors.lightTaupe)
                        .tracking(2.0)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.0f", scan.glowScore))
                            .font(.gbDisplayM)
                            .tracking(-0.5)
                            .foregroundStyle(GlowbiteColors.trafficLight(for: scan.glowScore))

                        Text("Glow Score")
                            .font(.gbCaption)
                            .foregroundStyle(GlowbiteColors.lightTaupe)
                    }

                    HStack(spacing: 10) {
                        ForEach(topMetrics) { metric in
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(GlowbiteColors.trafficLight(for: metric.score))
                                    .frame(width: 5, height: 5)

                                Text("\(metric.type.displayName) \(Int(metric.score))")
                                    .font(.gbCaption)
                                    .foregroundStyle(GlowbiteColors.warmBrown)
                            }
                        }
                    }

                    Text(scan.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.gbOverline)
                        .tracking(2.0)
                        .foregroundStyle(GlowbiteColors.lightTaupe)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 110)
            .background(GlowbiteColors.white)
            .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
            .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Food Activity Card (Premium/Editorial)

struct FoodActivityCard: View {
    let foodScan: FoodScan
    let onTap: () -> Void

    private var scoreColor: Color {
        GlowbiteColors.trafficLight(for: foodScan.skinImpactScore * 10)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                ZStack {
                    GlowbiteColors.peachWash

                    if let data = foodScan.photoData,
                       let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text("\u{1F37D}")
                            .font(.gbDisplayL)
                            .tracking(-1.0)
                    }
                }
                .frame(width: 90)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text("FOOD LOG")
                        .font(.gbOverline)
                        .foregroundStyle(GlowbiteColors.lightTaupe)
                        .tracking(2.0)

                    Text(foodScan.name)
                        .font(.gbTitleM)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                        .lineLimit(1)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f", foodScan.skinImpactScore))
                            .font(.gbDisplayM)
                            .tracking(-0.5)
                            .foregroundStyle(scoreColor)

                        Text("Skin Impact")
                            .font(.gbCaption)
                            .foregroundStyle(GlowbiteColors.lightTaupe)
                    }

                    HStack(spacing: 8) {
                        nutritionItem(value: "\(foodScan.calories)", unit: "cal")
                        nutritionItem(value: String(format: "%.0fg", foodScan.protein), unit: "pro")
                        nutritionItem(value: String(format: "%.0fg", foodScan.fat), unit: "fat")
                    }

                    Text(foodScan.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.gbOverline)
                        .tracking(2.0)
                        .foregroundStyle(GlowbiteColors.lightTaupe)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 110)
            .background(GlowbiteColors.white)
            .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
            .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func nutritionItem(value: String, unit: String) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.darkBrown)
            Text(unit)
                .font(.gbOverline)
                .tracking(2.0)
                .foregroundStyle(GlowbiteColors.warmBrown)
        }
    }
}

// MARK: - Unified Activity Item

enum ActivityItem: Identifiable {
    case face(SkinScan)
    case food(FoodScan)

    var id: String {
        switch self {
        case .face(let scan): return "face-\(scan.id)"
        case .food(let scan): return "food-\(scan.id)"
        }
    }

    var date: Date {
        switch self {
        case .face(let scan): return scan.createdAt
        case .food(let scan): return scan.createdAt
        }
    }
}
