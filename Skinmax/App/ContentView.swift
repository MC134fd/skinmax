import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showScanPopup = false
    @State private var showFaceScan = false
    @State private var showFoodLogSheet = false
    @State private var showFaceResult = false
    @State private var showFoodResult = false
    @State private var faceResultScan: SkinScan?
    @State private var foodResultScan: FoodScan?

    @Environment(AnalysisCoordinator.self) private var coordinator

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                Tab("Home", systemImage: "house.fill", value: TabItem.home) {
                    HomeView(
                        onViewFaceResult: { scan in
                            faceResultScan = scan
                            showFaceResult = true
                        },
                        onViewFoodResult: { scan in
                            foodResultScan = scan
                            showFoodResult = true
                        },
                        onScanMeal: {
                            showScanPopup = true
                        }
                    )
                }

                Tab("Analytics", systemImage: "chart.bar.fill", value: TabItem.analytics) {
                    AnalyticsContainerView()
                }

                Tab("Account", systemImage: "person.fill", value: TabItem.account) {
                    NavigationStack {
                        AccountView()
                    }
                }
            }
            .tint(GlowbiteColors.coral)
            .tabBarMinimizeBehavior(.onScrollDown)
            .tabViewBottomAccessory {
                Button {
                    HapticManager.impact(.medium)
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        showScanPopup.toggle()
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                        Text("Scan")
                    }
                    .font(.gbTitleM)
                }
                .tint(GlowbiteColors.coral)
            }
            .onChange(of: selectedTab) { _, _ in
                HapticManager.selection()
            }

            // Scan popup overlay
            if showScanPopup {
                ScanPopupOverlay(
                    isPresented: $showScanPopup,
                    onScanFace: {
                        showFaceScan = true
                    },
                    onLogFood: {
                        showFoodLogSheet = true
                    }
                )
            }
        }
        .fullScreenCover(isPresented: $showFaceScan) {
            FaceScanView()
        }
        .fullScreenCover(isPresented: $showFoodLogSheet) {
            FoodLogSheet()
        }
        .fullScreenCover(isPresented: $showFaceResult) {
            if let scan = faceResultScan {
                FaceScanResultView(scan: scan)
            }
        }
        .fullScreenCover(isPresented: $showFoodResult) {
            if let scan = foodResultScan {
                FoodScanResultView(scan: scan)
            }
        }
    }
}

#Preview {
    ContentView()
}
