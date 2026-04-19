import SwiftUI
import SwiftData

@main
struct GlowbiteApp: App {
    let container: ModelContainer
    let dataStore: DataStore
    @State private var analysisCoordinator = AnalysisCoordinator()
    @State private var authService = AuthService()

    init() {
        let schema = Schema([CachedSkinScan.self, CachedFoodScan.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: config)
        self.container = container
        self.dataStore = DataStore(modelContext: container.mainContext)

        Config.validateAPIKey()
        Config.validateSupabase()
        dataStore.pruneExpiredCache()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if authService.isLoading {
                    splashView
                } else if authService.isAuthenticated {
                    ContentView()
                } else {
                    AuthView()
                }
            }
            .environment(dataStore)
            .environment(analysisCoordinator)
            .environment(authService)
            .modelContainer(container)
        }
    }

    private var splashView: some View {
        ZStack {
            GlowbiteColors.creamBG.ignoresSafeArea()
            GlowbiteLockup(variant: .caveat, iconSize: 48, gap: 10, wordmarkSize: 52)
        }
    }
}
