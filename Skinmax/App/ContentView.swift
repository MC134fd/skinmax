import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showScanPopup = false
    @State private var showFaceScan = false
    @State private var showFoodCapture = false
    @State private var faceResultScan: SkinScan?
    @State private var foodResultScan: FoodScan?
    @Namespace private var tabAnimation

    @Environment(AnalysisCoordinator.self) private var coordinator

    var body: some View {
        ZStack(alignment: .bottom) {
            GlowbiteColors.creamBG.ignoresSafeArea()

            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        onViewFaceResult: { scan in
                            faceResultScan = scan
                        },
                        onViewFoodResult: { scan in
                            foodResultScan = scan
                        },
                        onScanMeal: {
                            showScanPopup = true
                        }
                    )
                case .analytics:
                    AnalyticsContainerView()
                case .account:
                    AccountView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 80)

            bottomBar
                .padding(.horizontal, 10)
                .padding(.bottom, 2)

            if showScanPopup {
                ScanPopupOverlay(
                    isPresented: $showScanPopup,
                    onScanFace: {
                        showFaceScan = true
                    },
                    onLogFood: {
                        showFoodCapture = true
                    }
                )
            }
        }
        .ignoresSafeArea(.keyboard)
        .fullScreenCover(isPresented: $showFaceScan) {
            FaceScanView()
        }
        .fullScreenCover(isPresented: $showFoodCapture) {
            FoodCaptureView()
        }
        .sheet(item: $faceResultScan) { scan in
            FaceScanResultView(scan: scan)
                .presentationDetents([.large])
                .presentationCornerRadius(GlowbiteSpacing.cardCornerRadiusLarge)
                .presentationDragIndicator(.visible)
        }
        .sheet(item: $foodResultScan) { scan in
            FoodScanResultView(scan: scan)
                .presentationDetents([.large])
                .presentationCornerRadius(GlowbiteSpacing.cardCornerRadiusLarge)
                .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Bottom Bar (tab pill + scan circle, side by side)

    private var bottomBar: some View {
        HStack(spacing: 8) {
            // Tab bar pill
            HStack(spacing: 0) {
                ForEach(TabItem.allCases, id: \.self) { tab in
                    Button {
                        HapticManager.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: tab.systemIcon)
                                .font(.system(size: 18, weight: .medium))
                            Text(tab.title)
                                .font(.gbOverline)
                        }
                        .foregroundStyle(selectedTab == tab ? GlowbiteColors.coral : GlowbiteColors.mediumTaupe)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(Color.black.opacity(0.08))
                                    .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.75), in: Capsule())
            .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)

            // Scan circle button — same height as tab pill
            Button {
                HapticManager.impact(.medium)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    showScanPopup.toggle()
                }
            } label: {
                Image(systemName: showScanPopup ? "xmark" : "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(GlowbiteColors.darkBrown)
                    .clipShape(Circle())
                    .shadow(color: GlowbiteColors.cardShadowColor, radius: 12, x: 0, y: 4)
                    .rotationEffect(.degrees(showScanPopup ? 90 : 0))
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
}

#Preview {
    ContentView()
}
