import SwiftUI

struct ProgressView_: View {
    @Environment(DataStore.self) private var dataStore
    @State private var selectedComparisonIndex: Int = 0

    private var allScans: [SkinScan] { dataStore.allSkinScans() }
    private var latestScan: SkinScan? { allScans.first }
    private var comparisonScan: SkinScan? {
        guard allScans.count > 1 else { return nil }
        let idx = min(selectedComparisonIndex, allScans.count - 1)
        return allScans[idx]
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if allScans.count < 2 {
                emptyState
            } else {
                VStack(spacing: 18) {
                    photoComparison
                    scoreChangeCard
                    timelineScrubber
                    keyChanges
                }
                .padding(.horizontal, SkinmaxSpacing.screenPadding)
                .padding(.bottom, 100)
            }
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
        .navigationTitle("Progress")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Default to oldest scan for comparison
            if allScans.count > 1 {
                selectedComparisonIndex = allScans.count - 1
            }
        }
    }

    // MARK: - Photo Comparison
    private var photoComparison: some View {
        HStack(spacing: 12) {
            if let comparison = comparisonScan {
                scanPhotoCard(scan: comparison, label: "Before")
            }
            if let latest = latestScan {
                scanPhotoCard(scan: latest, label: "Latest")
            }
        }
    }

    private func scanPhotoCard(scan: SkinScan, label: String) -> some View {
        VStack(spacing: 8) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [SkinmaxColors.peachLight, SkinmaxColors.coral.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "face.smiling")
                        .font(.system(size: 40))
                        .foregroundStyle(.white.opacity(0.7))
                )

            Text(scan.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                .font(SkinmaxFonts.caption())
                .foregroundStyle(SkinmaxColors.mutedTan)

            Text(String(format: "%.0f", scan.glowScore))
                .font(.custom("Nunito-Bold", size: 16))
                .foregroundStyle(SkinmaxColors.trafficLight(for: scan.glowScore))

            Text(label)
                .font(SkinmaxFonts.small())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Score Change Card
    private var scoreChangeCard: some View {
        Group {
            if let comparison = comparisonScan, let latest = latestScan {
                let diff = Int(latest.glowScore - comparison.glowScore)
                HStack {
                    Text(String(format: "%.0f", comparison.glowScore))
                        .font(.custom("Nunito-Bold", size: 22))
                        .foregroundStyle(SkinmaxColors.mutedTan)

                    Text("→")
                        .foregroundStyle(SkinmaxColors.mutedTan)

                    Text(String(format: "%.0f", latest.glowScore))
                        .font(.custom("Nunito-Bold", size: 22))
                        .foregroundStyle(SkinmaxColors.trafficLight(for: latest.glowScore))

                    Spacer()

                    Text(diff >= 0 ? "+\(diff)" : "\(diff)")
                        .font(.custom("Nunito-SemiBold", size: 13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(diff >= 0 ? SkinmaxColors.greenGood : SkinmaxColors.redAlert)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .padding(SkinmaxSpacing.cardPadding)
                .background(SkinmaxColors.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
        }
    }

    // MARK: - Timeline Scrubber
    private var timelineScrubber: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(Array(allScans.enumerated().reversed()), id: \.element.id) { index, scan in
                    let isSelected = index == selectedComparisonIndex
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            selectedComparisonIndex = index
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Circle()
                                .fill(isSelected ? SkinmaxColors.coral : SkinmaxColors.lightTan)
                                .frame(width: isSelected ? 12 : 8, height: isSelected ? 12 : 8)
                                .overlay(
                                    isSelected ? Circle().stroke(SkinmaxColors.coral.opacity(0.3), lineWidth: 3) : nil
                                )

                            Text(scan.createdAt.formatted(.dateTime.month(.abbreviated).day()))
                                .font(SkinmaxFonts.small())
                                .foregroundStyle(isSelected ? SkinmaxColors.coral : SkinmaxColors.mutedTan)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    // MARK: - Key Changes
    private var keyChanges: some View {
        Group {
            if let comparison = comparisonScan, let latest = latestScan {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Key Changes")
                        .font(SkinmaxFonts.h3())
                        .foregroundStyle(SkinmaxColors.darkBrown)

                    let changes = metricChanges(from: comparison, to: latest)
                    if changes.isEmpty {
                        Text("No significant changes detected")
                            .font(SkinmaxFonts.body())
                            .foregroundStyle(SkinmaxColors.mutedTan)
                    } else {
                        ForEach(changes, id: \.name) { change in
                            HStack {
                                Text(change.name)
                                    .font(SkinmaxFonts.body())
                                    .foregroundStyle(SkinmaxColors.warmGray)
                                Spacer()
                                Text(change.pct >= 0 ? "+\(change.pct)%" : "\(change.pct)%")
                                    .font(.custom("Nunito-SemiBold", size: 13))
                                    .foregroundStyle(change.pct >= 0 ? SkinmaxColors.greenGood : SkinmaxColors.redAlert)
                            }
                        }
                    }
                }
                .padding(SkinmaxSpacing.cardPadding)
                .background(SkinmaxColors.white)
                .clipShape(RoundedRectangle(cornerRadius: SkinmaxSpacing.cardCornerRadius))
                .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            }
        }
    }

    private func metricChanges(from old: SkinScan, to new: SkinScan) -> [(name: String, pct: Int)] {
        var changes: [(name: String, pct: Int)] = []
        for newMetric in new.metrics {
            if let oldMetric = old.metrics.first(where: { $0.type == newMetric.type }) {
                let diff = Int(newMetric.score - oldMetric.score)
                if abs(diff) > 5 {
                    changes.append((name: newMetric.type.displayName, pct: diff))
                }
            }
        }
        return changes.sorted { abs($0.pct) > abs($1.pct) }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)
            Text("📸").font(.system(size: 40))
            Text("Take at least 2 face scans to compare progress")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)
                .multilineTextAlignment(.center)
            Text("Your first scan sets the baseline")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, SkinmaxSpacing.screenPadding)
    }
}
