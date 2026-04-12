import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showScanPopup = false
    @State private var showFaceScan = false
    @State private var showFoodLogSheet = false
    @State private var faceResultScan: SkinScan?
    @State private var foodResultScan: FoodScan?

    @Environment(AnalysisCoordinator.self) private var coordinator
    @Environment(DataStore.self) private var dataStore

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
                        },
                        onViewFoodResult: { scan in
                            foodResultScan = scan
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
                .environment(dataStore)
                .environment(coordinator)
        }
        .fullScreenCover(isPresented: $showFoodLogSheet) {
            FoodLogSheet()
                .environment(dataStore)
                .environment(coordinator)
        }
        .fullScreenCover(item: $faceResultScan) { scan in
            FaceScanResultView(scan: scan)
                .environment(dataStore)
        }
        .fullScreenCover(item: $foodResultScan) { scan in
            FoodScanResultView(scan: scan)
                .environment(dataStore)
        }
    }
}

#Preview {
    ContentView()
}
