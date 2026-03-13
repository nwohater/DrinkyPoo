import SwiftUI
import SwiftData

/// Root tab container.
struct ContentView: View {
    var iCloudAvailable: Bool = true

    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Home",     systemImage: "house.fill") }

            NavigationStack { CalendarView() }
                .tabItem { Label("Calendar", systemImage: "calendar") }

            NavigationStack { TrendsView() }
                .tabItem { Label("Trends",   systemImage: "chart.bar.fill") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .preferredColorScheme(preferredColorScheme)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
