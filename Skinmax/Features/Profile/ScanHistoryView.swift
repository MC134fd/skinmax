import SwiftUI

struct ScanHistoryView: View {
    @Environment(DataStore.self) private var dataStore
    @State private var selectedScan: SkinScan?
    @State private var scanToDelete: SkinScan?

    private var scans: [SkinScan] { dataStore.allSkinScans() }

    var body: some View {
        Group {
            if scans.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(scans) { scan in
                        ScanHistoryRow(scan: scan) {
                            selectedScan = scan
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                scanToDelete = scan
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: SkinmaxSpacing.screenPadding, bottom: 6, trailing: SkinmaxSpacing.screenPadding))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .scrollIndicators(.hidden)
                .contentMargins(.bottom, 100)
            }
        }
        .background(SkinmaxColors.creamBG.ignoresSafeArea())
        .navigationTitle("Scan History")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $selectedScan) { scan in
            FaceScanResultView(scan: scan)
                .environment(dataStore)
        }
        .alert("Delete Scan", isPresented: Binding(
            get: { scanToDelete != nil },
            set: { if !$0 { scanToDelete = nil } }
        )) {
            Button("Cancel", role: .cancel) {
                scanToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let scan = scanToDelete {
                    HapticManager.notification(.warning)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        dataStore.deleteSkinScan(id: scan.id)
                    }
                    HapticManager.notification(.success)
                }
                scanToDelete = nil
            }
        } message: {
            Text("This scan and its data will be permanently removed.")
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
                .font(.gbBodyM)
                .foregroundStyle(SkinmaxColors.lightTaupe)
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
                        .font(.gbCaption)
                        .foregroundStyle(SkinmaxColors.darkBrown)

                    Text(scan.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.gbCaption)
                        .foregroundStyle(SkinmaxColors.lightTaupe)

                    Text("\(scan.metrics.count) metrics analyzed")
                        .font(.gbCaption)
                        .foregroundStyle(SkinmaxColors.lightTaupe)
                }

                Spacer()

                Text(String(format: "%.0f", scan.glowScore))
                    .font(.gbTitleL)
                    .foregroundStyle(scoreColor)
            }
            .padding(14)
            .background(SkinmaxColors.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: SkinmaxColors.cardShadowColor, radius: 12, x: 0, y: 4)
        }
    }
}
