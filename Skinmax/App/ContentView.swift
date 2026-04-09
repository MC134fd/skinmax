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
            SkinmaxColors.creamBG.ignoresSafeArea()

            // Main content
            Group {
                switch selectedTab {
                case .home:
                    HomeView(
                        onViewFaceResult: { scan in
                            faceResultScan = scan
                            showFaceResult = true
                        },
                        onViewFoodResult: { scan in
                            foodResultScan = scan
                            showFoodResult = true
                        }
                    )
                case .analytics:
                    AnalyticsContainerView()
                case .account:
                    NavigationStack {
                        AccountView()
                    }
                }
            }

            // Tab bar
            VStack {
                Spacer()
                GlassTabBar(selectedTab: $selectedTab, showScanPopup: $showScanPopup)
                    .padding(.bottom, 4)
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
