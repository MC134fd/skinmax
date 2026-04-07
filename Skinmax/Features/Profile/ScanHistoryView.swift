import SwiftUI

struct ScanHistoryView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var selectedScan: SkinScan?
    @State private var showResult = false

    private var scans: [SkinScan] { dataStore.allSkinScans() }

    var body: some View {
        ScrollView(showsIndicators: false) {
            if scans.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(scans) { scan in
                        ScanHistoryRow(scan: scan) {
                            selectedScan = scan
                            showResult = true
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                HapticManager.notification(.warning)
                                dataStore.deleteSkinScan(id: scan.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .padding(.horizontal, SkinmaxSpacing.screenPadding)
                .padding(.bottom, 100)
            }
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
        .navigationTitle("Scan History")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showResult) {
            if let scan = selectedScan {
                FaceScanResultView(scan: scan)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer().frame(height: 80)
            Text("🔍").font(.system(size: 40))
            Text("No scans yet")
                .font(SkinmaxFonts.h3())
                .foregroundStyle(SkinmaxColors.darkBrown)
            Text("Take your first face scan to start tracking")
                .font(SkinmaxFonts.body())
                .foregroundStyle(SkinmaxColors.mutedTan)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Scan History Row
struct ScanHistoryRow: View {
    let scan: SkinScan
    let onTap: () -> Void

    private var scoreColor: Color { SkinmaxColors.trafficLight(for: scan.glowScore) }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Placeholder avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [SkinmaxColors.peachLight, SkinmaxColors.coral],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "face.smiling")
                            .font(.system(size: 22))
                            .foregroundStyle(.white.opacity(0.8))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(scan.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.custom("Nunito-SemiBold", size: 13))
                        .foregroundStyle(SkinmaxColors.darkBrown)

                    Text(scan.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(SkinmaxColors.mutedTan)

                    Text("\(scan.metrics.count) metrics analyzed")
                        .font(SkinmaxFonts.caption())
                        .foregroundStyle(SkinmaxColors.mutedTan)
                }

                Spacer()

                Text(String(format: "%.0f", scan.glowScore))
                    .font(.custom("Nunito-Bold", size: 22))
                    .foregroundStyle(scoreColor)
            }
            .padding(14)
            .background(SkinmaxColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
        }
    }
}
