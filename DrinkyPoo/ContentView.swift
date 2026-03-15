import SwiftUI
import SwiftData

// MARK: - Milestone notification
extension Notification.Name {
    static let dryMilestoneReached = Notification.Name("dryMilestoneReached")
}

/// Root tab container.
struct ContentView: View {
    var iCloudAvailable: Bool = true

    @AppStorage("appearanceMode") private var appearanceMode: String = "system"
    @State private var showSplash = true
    @State private var showConfetti = false

    private var preferredColorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark":  return .dark
        default:      return nil
        }
    }

    var body: some View {
        ZStack {
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

            if showConfetti {
                ConfettiView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .zIndex(2)
            }

            if showSplash {
                SplashView()
                    .transition(.opacity)
                    .zIndex(3)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .dryMilestoneReached)) { _ in
            showConfetti = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                showConfetti = false
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeOut(duration: 0.4)) {
                showSplash = false
            }
        }
    }
}

// MARK: - SplashView

private struct SplashView: View {
    var body: some View {
        Color("AppBackground")
            .ignoresSafeArea()
            .overlay {
                Image("LaunchIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
            }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
