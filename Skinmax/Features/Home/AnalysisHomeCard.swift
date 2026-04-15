import SwiftUI

struct AnalysisHomeCard: View {
    let coordinator: AnalysisCoordinator
    var onViewFaceResult: (SkinScan) -> Void = { _ in }
    var onViewFoodResult: (FoodScan) -> Void = { _ in }
    var onDismiss: () -> Void = {}

    @State private var pulseOpacity: Double = 1.0

    private var isComplete: Bool {
        if case .complete = coordinator.phase { return true }
        return false
    }

    private var isError: Bool {
        if case .error = coordinator.phase { return true }
        return false
    }

    var body: some View {
        HStack(spacing: 14) {
            progressRing
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                if isComplete {
                    completeContent
                } else if isError {
                    errorContent
                } else {
                    analyzingContent
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(GlowbiteSpacing.cardPadding)
        .background(GlowbiteColors.white)
        .clipShape(RoundedRectangle(cornerRadius: GlowbiteSpacing.cardCornerRadius))
        .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
        .onAppear {
            startPulse()
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(GlowbiteColors.softTan, lineWidth: 5)

            Circle()
                .trim(from: 0, to: coordinator.progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: coordinator.progress)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.greenGood)
            } else if isError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.gbBodyL)
                    .foregroundStyle(GlowbiteColors.redAlert)
            } else {
                Text("\(Int(coordinator.progress * 100))%")
                    .font(.gbBodyM)
                    .foregroundStyle(GlowbiteColors.darkBrown)
            }
        }
    }

    private var ringColor: Color {
        if isComplete { return GlowbiteColors.greenGood }
        if isError { return GlowbiteColors.redAlert }
        return GlowbiteColors.coral
    }

    // MARK: - Analyzing State

    private var analyzingContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(coordinator.kind == .face ? "Analyzing Skin" : "Analyzing Food")
                .font(.gbTitleM)
                .foregroundStyle(GlowbiteColors.darkBrown)
                .opacity(pulseOpacity)

            Text(coordinator.phase.label)
                .font(.gbCaption)
                .foregroundStyle(GlowbiteColors.lightTaupe)
        }
    }

    // MARK: - Complete State

    private var completeContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if coordinator.kind == .face, let scan = coordinator.faceScanResult {
                Text("Glow Score: \(Int(scan.glowScore))")
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Button {
                    onViewFaceResult(scan)
                } label: {
                    Text("View Results")
                        .font(.gbCaption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(GlowbiteColors.coral)
                        .clipShape(Capsule())
                }
            } else if coordinator.kind == .food, let scan = coordinator.foodScanResult {
                Text("\(scan.name) — \(String(format: "%.1f", scan.skinImpactScore))/10")
                    .font(.gbTitleM)
                    .foregroundStyle(GlowbiteColors.darkBrown)

                Button {
                    onViewFoodResult(scan)
                } label: {
                    Text("View Results")
                        .font(.gbCaption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(GlowbiteColors.coral)
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Error State

    private var errorContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if case .error(let msg) = coordinator.phase {
                Text(msg)
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.redAlert)
                    .lineLimit(2)
            }

            Button {
                onDismiss()
            } label: {
                Text("Dismiss")
                    .font(.gbCaption)
                    .foregroundStyle(GlowbiteColors.coral)
            }
        }
    }

    // MARK: - Pulse Animation

    private func startPulse() {
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.4
        }
    }
}
