import SwiftUI
import SwiftData

@main
struct DrinkyPooWatchApp: App {
    let modelContainer: ModelContainer

    init() {
        let (container, _) = DrinkyPooModelContainerFactory.makeModelContainer()
        self.modelContainer = container
    }

    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
        .modelContainer(modelContainer)
    }
}
