import SwiftUI
import SwiftData

@main
struct DrinkyPooApp: App {

    let modelContainer: ModelContainer
    @State private var iCloudAvailable: Bool

    init() {
        let (container, cloudEnabled) = DrinkyPooModelContainerFactory.makeModelContainer()
        self.modelContainer = container
        self._iCloudAvailable = State(initialValue: cloudEnabled)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(iCloudAvailable: iCloudAvailable)
        }
        .modelContainer(modelContainer)
    }
}
