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
            // Left: Progress ring
            progressRing
                .frame(width: 64, height: 64)

            // Right: Status content
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
        .padding(16)
        .background(SkinmaxColors.white)
        .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        .onAppear {
            startPulse()
        }
    }

    // MARK: - Progress Ring

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(SkinmaxColors.lightTan, lineWidth: 5)

            Circle()
                .trim(from: 0, to: coordinator.progress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: coordinator.progress)

            if isComplete {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(SkinmaxColors.greenGood)
            } else if isError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(SkinmaxColors.redAlert)
            } else {
                Text("\(Int(coordinator.progress * 100))%")
                    .font(.custom("Nunito-Bold", size: 14))
                    .foregroundStyle(SkinmaxColors.darkBrown)
            }
        }
    }

    private var ringColor: Color {
        if isComplete { return SkinmaxColors.greenGood }
        if isError { return SkinmaxColors.redAlert }
        return SkinmaxColors.coral
    }

    // MARK: - Analyzing State

    private var analyzingContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(coordinator.kind == .face ? "Analyzing Skin" : "Analyzing Food")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)
                .opacity(pulseOpacity)

            Text(coordinator.phase.label)
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)
        }
    }

    // MARK: - Complete State

    private var completeContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            if coordinator.kind == .face, let scan = coordinator.faceScanResult {
                Text("Glow Score: \(Int(scan.glowScore))")
                    .font(SkinmaxFonts.h3())
                    .foregroundStyle(SkinmaxColors.darkBrown)

                Button {
                    onViewFaceResult(scan)
                } label: {
                    Text("View Results")
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(SkinmaxColors.coral)
                        .clipShape(Capsule())
                }
            } else if coordinator.kind == .food, let scan = coordinator.foodScanResult {
                Text("\(scan.name) — \(String(format: "%.1f", scan.skinImpactScore))/10")
                    .font(SkinmaxFonts.h3())
                    .foregroundStyle(SkinmaxColors.darkBrown)

                Button {
                    onViewFoodResult(scan)
                } label: {
                    Text("View Results")
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(SkinmaxColors.coral)
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
                    .font(SkinmaxFonts.caption())
                    .foregroundStyle(SkinmaxColors.redAlert)
                    .lineLimit(2)
            }

            Button {
                onDismiss()
            } label: {
                Text("Dismiss")
                    .font(SkinmaxFonts.caption())
                    .foregroundStyle(SkinmaxColors.coral)
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
