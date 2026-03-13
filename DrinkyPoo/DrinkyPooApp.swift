import SwiftUI
import SwiftData

@main
struct DrinkyPooApp: App {

    let modelContainer: ModelContainer
    @State private var iCloudAvailable: Bool

    init() {
        let (container, cloudEnabled) = Self.makeModelContainer()
        self.modelContainer = container
        self._iCloudAvailable = State(initialValue: cloudEnabled)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(iCloudAvailable: iCloudAvailable)
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Container setup

    private static func makeModelContainer() -> (ModelContainer, Bool) {
        let schema = Schema([DayEntry.self])

        // Try CloudKit-backed storage first
        do {
            let config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.golackey.DrinkyPoo")
            )
            let container = try ModelContainer(for: schema, configurations: [config])
            return (container, true)
        } catch {
            print("[DrinkyPoo] CloudKit container unavailable: \(error). Falling back to local storage.")
        }

        // Fall back to local storage
        return (makeLocalContainer(schema: schema), false)
    }

    private static func makeLocalContainer(schema: Schema) -> ModelContainer {
        let storeURL = URL.applicationSupportDirectory
            .appendingPathComponent("DrinkyPoo.sqlite")

        let config = ModelConfiguration(schema: schema, url: storeURL)

        // First attempt
        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        // Store is corrupt or schema changed — wipe and recreate.
        // Safe during development; real migration plans added before shipping.
        print("[DrinkyPoo] Local store load failed — wiping and recreating.")
        for ext in ["sqlite", "sqlite-shm", "sqlite-wal"] {
            let url = URL.applicationSupportDirectory.appendingPathComponent("DrinkyPoo.\(ext)")
            try? FileManager.default.removeItem(at: url)
        }

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("[DrinkyPoo] Could not create ModelContainer even after reset: \(error)")
        }
    }
}
