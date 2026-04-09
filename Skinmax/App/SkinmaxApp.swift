import SwiftUI
import SwiftData

@main
struct SkinmaxApp: App {
    let container: ModelContainer
    let dataStore: DataStore
    @State private var analysisCoordinator = AnalysisCoordinator()

    init() {
        let schema = Schema([CachedSkinScan.self, CachedFoodScan.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        let container = try! ModelContainer(for: schema, configurations: config)
        self.container = container
        self.dataStore = DataStore(modelContext: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataStore)
                .environment(analysisCoordinator)
                .modelContainer(container)
        }
    }
}
