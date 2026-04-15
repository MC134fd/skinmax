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
                    SkinmaxColors.heroGradient

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
                    }
                }
                .frame(width: 90)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text("FACE SCAN")
                        .font(.gbOverline)
                        .foregroundStyle(SkinmaxColors.lightTaupe)
                        .tracking(1.5)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.0f", scan.glowScore))
                            .font(.gbDisplayM)
                            .foregroundStyle(SkinmaxColors.trafficLight(for: scan.glowScore))

                        Text("Glow Score")
                            .font(.gbCaption)
                            .foregroundStyle(SkinmaxColors.lightTaupe)
                    }

                    HStack(spacing: 10) {
                        ForEach(topMetrics) { metric in
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(SkinmaxColors.trafficLight(for: metric.score))
                                    .frame(width: 5, height: 5)

                                Text("\(metric.type.displayName) \(Int(metric.score))")
                                    .font(.gbCaption)
                                    .foregroundStyle(SkinmaxColors.warmBrown)
                            }
                        }
                    }

                    Text(scan.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.gbOverline)
                        .foregroundStyle(SkinmaxColors.lightTaupe)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 110)
            .background(SkinmaxColors.white)
            .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
            .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Food Activity Card (Premium/Editorial)

struct FoodActivityCard: View {
    let foodScan: FoodScan
    let onTap: () -> Void

    private var scoreColor: Color {
        SkinmaxColors.trafficLight(for: foodScan.skinImpactScore * 10)
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                ZStack {
                    SkinmaxColors.peachWash

                    if let data = foodScan.photoData,
                       let img = UIImage(data: data) {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Text("\u{1F37D}")
                            .font(.gbDisplayL)
                    }
                }
                .frame(width: 90)
                .clipped()

                VStack(alignment: .leading, spacing: 4) {
                    Text("FOOD LOG")
                        .font(.gbOverline)
                        .foregroundStyle(SkinmaxColors.lightTaupe)
                        .tracking(1.5)

                    Text(foodScan.name)
                        .font(.gbTitleM)
                        .foregroundStyle(SkinmaxColors.darkBrown)
                        .lineLimit(1)

                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(String(format: "%.1f", foodScan.skinImpactScore))
                            .font(.gbDisplayM)
                            .foregroundStyle(scoreColor)

                        Text("Skin Impact")
                            .font(.gbCaption)
                            .foregroundStyle(SkinmaxColors.lightTaupe)
                    }

                    HStack(spacing: 8) {
                        nutritionItem(value: "\(foodScan.calories)", unit: "cal")
                        nutritionItem(value: String(format: "%.0fg", foodScan.protein), unit: "pro")
                        nutritionItem(value: String(format: "%.0fg", foodScan.fat), unit: "fat")
                    }

                    Text(foodScan.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.gbOverline)
                        .foregroundStyle(SkinmaxColors.lightTaupe)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 110)
            .background(SkinmaxColors.white)
            .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
            .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func nutritionItem(value: String, unit: String) -> some View {
        HStack(spacing: 2) {
            Text(value)
                .font(.gbOverline)
                .foregroundStyle(SkinmaxColors.darkBrown)
            Text(unit)
                .font(.gbOverline)
                .foregroundStyle(SkinmaxColors.warmBrown)
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
