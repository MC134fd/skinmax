import SwiftUI

// MARK: - Completed meal card (data from saved FoodScan)
struct MealRow: View {
    let foodScan: FoodScan
    var onTapCard: () -> Void = {}

    private var scoreColor: Color {
        switch foodScan.skinImpactScore {
        case 7...10: return GlowbiteColors.greenGood
        case 4..<7: return GlowbiteColors.amberFair
        default: return GlowbiteColors.redAlert
        }
    }

    private var foodImage: UIImage? {
        guard let data = foodScan.photoData else { return nil }
        return UIImage(data: data)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Photo
            FoodCardPhoto(image: foodImage)

            // Info + score
            HStack(spacing: 0) {
                // Left: food details
                VStack(alignment: .leading, spacing: 5) {
                    Text(foodScan.name)
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                        .lineLimit(1)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(foodScan.calories)")
                            .font(.gbTitleM)
                            .foregroundStyle(GlowbiteColors.darkBrown)
                        Text("kcal")
                            .font(.gbCaption)
                            .foregroundStyle(GlowbiteColors.lightTaupe)
                    }

                    HStack(spacing: 5) {
                        MacroPill(value: foodScan.protein, label: "P", color: GlowbiteColors.nutrientProtein)
                        MacroPill(value: foodScan.carbs, label: "C", color: GlowbiteColors.nutrientCarbs)
                        MacroPill(value: foodScan.fat, label: "F", color: GlowbiteColors.nutrientFat)
                    }
                }
                .padding(.leading, 14)
                .padding(.vertical, 12)

                Spacer(minLength: 8)

                // Right: score + time stacked
                VStack(spacing: 4) {
                    Text(foodScan.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.lightTaupe)

                    Text(String(format: "%.0f", foodScan.skinImpactScore))
                        .font(.gbDisplayM)
                        .foregroundStyle(scoreColor)

                    Text("/10")
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.lightTaupe)
                }
                .padding(.trailing, 14)
            }
        }
        .frame(height: 120)
        .background(
            LinearGradient(
                colors: [.white, GlowbiteColors.sunnyButter],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius, style: .continuous))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius, style: .continuous))
        .onTapGesture {
            onTapCard()
        }
    }
}

// MARK: - Live meal card (analyzing → completed in-place)
struct MealRowLive: View {
    let coordinator: AnalysisCoordinator
    var onTapCard: () -> Void = {}

    @State private var pulseOpacity: Double = 1.0

    private var isComplete: Bool {
        if case .complete = coordinator.phase { return true }
        return false
    }

    private var isError: Bool {
        if case .error = coordinator.phase { return true }
        return false
    }

    private var displayImage: UIImage? {
        // Prefer completed scan photo, fall back to pending capture
        if let data = coordinator.foodScanResult?.photoData {
            return UIImage(data: data)
        }
        if let data = coordinator.pendingFoodImageData {
            return UIImage(data: data)
        }
        return nil
    }

    private var scan: FoodScan? { coordinator.foodScanResult }

    private var scoreColor: Color {
        guard let score = scan?.skinImpactScore else { return GlowbiteColors.lightTaupe }
        switch score {
        case 7...10: return GlowbiteColors.greenGood
        case 4..<7: return GlowbiteColors.amberFair
        default: return GlowbiteColors.redAlert
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            FoodCardPhoto(image: displayImage)

            // Right side: crossfade between analyzing and completed
            ZStack {
                if isComplete, let scan {
                    completedContent(scan: scan)
                        .transition(.opacity)
                } else if isError, case .error(let msg) = coordinator.phase {
                    errorContent(msg: msg)
                        .transition(.opacity)
                } else {
                    analyzingContent
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.35), value: isComplete)
            .animation(.easeInOut(duration: 0.35), value: isError)
        }
        .frame(height: 120)
        .background(
            LinearGradient(
                colors: isComplete ? [.white, GlowbiteColors.sunnyButter] : [.white, GlowbiteColors.peachWash],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .animation(.easeInOut(duration: 0.4), value: isComplete)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius, style: .continuous))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius, style: .continuous))
        .onTapGesture {
            if isComplete { onTapCard() }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                pulseOpacity = 0.4
            }
        }
    }

    // MARK: - Analyzing state
    private var analyzingContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Analyzing Food")
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.darkBrown)
                .opacity(pulseOpacity)

            Text(coordinator.phase.label)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.lightTaupe)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(GlowbiteColors.softTan)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(GlowbiteColors.coral)
                        .frame(width: geo.size.width * coordinator.progress, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: coordinator.progress)
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Completed state (same layout as MealRow)
    private func completedContent(scan: FoodScan) -> some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 5) {
                Text(scan.name)
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.darkBrown)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("\(scan.calories)")
                        .font(.gbTitleM)
                        .foregroundStyle(GlowbiteColors.darkBrown)
                    Text("kcal")
                        .font(.gbCaption)
                        .foregroundStyle(GlowbiteColors.lightTaupe)
                }

                HStack(spacing: 5) {
                    MacroPill(value: scan.protein, label: "P", color: GlowbiteColors.nutrientProtein)
                    MacroPill(value: scan.carbs, label: "C", color: GlowbiteColors.nutrientCarbs)
                    MacroPill(value: scan.fat, label: "F", color: GlowbiteColors.nutrientFat)
                }
            }
            .padding(.leading, 14)
            .padding(.vertical, 12)

            Spacer(minLength: 8)

            VStack(spacing: 4) {
                Text(scan.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)

                Text(String(format: "%.0f", scan.skinImpactScore))
                    .font(.gbDisplayM)
                    .foregroundStyle(scoreColor)

                Text("/10")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.lightTaupe)
            }
            .padding(.trailing, 14)
        }
    }

    // MARK: - Error state
    private func errorContent(msg: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(msg)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.redAlert)
                .lineLimit(2)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

// MARK: - Shared photo column
private struct FoodCardPhoto: View {
    let image: UIImage?

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    LinearGradient(
                        colors: [GlowbiteColors.peachWash, GlowbiteColors.creamBG],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Text("\u{1F37D}")
                        .font(.gbDisplayM)
                        .opacity(0.5)
                }
            }
        }
        .frame(width: 120)
        .clipped()
    }
}

// MARK: - Macro Pill
private struct MacroPill: View {
    let value: Double
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 2) {
            Text(String(format: "%.0fg", value))
                .fontWeight(.heavy)
            Text(label)
        }
        .font(.gbCaption)
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .overlay(
            Capsule()
                .stroke(color.opacity(0.3), lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
