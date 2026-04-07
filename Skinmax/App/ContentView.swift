import SwiftUI

struct ContentView: View {
    @State private var selectedTab: TabItem = .home
    @State private var showScanPopup = false
    @State private var showFaceScan = false
    @State private var showFoodLogSheet = false
    @State private var showFoodResult = false
    @State private var currentFoodScan: FoodScan?

    var body: some View {
        ZStack {
            SkinmaxColors.creamBG.ignoresSafeArea()

            // Main content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .analytics:
                    AnalyticsContainerView()
                case .account:
                    NavigationStack {
                        AccountView()
                    }
                case .scan:
                    HomeView()
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
        .sheet(isPresented: $showFoodLogSheet) {
            FoodLogSheet { result in
                currentFoodScan = result
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    showFoodResult = true
                }
            }
            .presentationDetents([.large])
        }
        .fullScreenCover(isPresented: $showFoodResult) {
            if let scan = currentFoodScan {
                FoodScanResultView(scan: scan)
            }
        }
    }
}

#Preview {
    ContentView()
}
