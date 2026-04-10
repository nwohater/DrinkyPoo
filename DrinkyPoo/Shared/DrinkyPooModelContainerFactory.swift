import Foundation
import SwiftData

enum DrinkyPooModelContainerFactory {
    static let cloudKitContainerIdentifier = "iCloud.com.golackey.DrinkyPoo"

    static func makeModelContainer() -> (ModelContainer, Bool) {
        let schema = Schema([DayEntry.self])

        do {
            let config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private(cloudKitContainerIdentifier)
            )
            let container = try ModelContainer(for: schema, configurations: [config])
            return (container, true)
        } catch {
            print("[DrinkyPoo] CloudKit container unavailable: \(error). Falling back to local storage.")
        }

        return (makeLocalContainer(schema: schema), false)
    }

    private static func makeLocalContainer(schema: Schema) -> ModelContainer {
        let storeURL = URL.applicationSupportDirectory
            .appendingPathComponent("DrinkyPoo.sqlite")

        let config = ModelConfiguration(schema: schema, url: storeURL)

        if let container = try? ModelContainer(for: schema, configurations: [config]) {
            return container
        }

        // Safe during development. We'll replace this with a migration strategy
        // before shipping more than a single schema.
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
