import SwiftUI
import SwiftData

struct InfoView: View {
    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(v) (\(b))"
    }

    var body: some View {
        List {
            aboutSection
            howToUseSection
            statsSection
            milestonesSection
            privacySection
            versionSection
        }
        .scrollContentBackground(.hidden)
        .background(Color("AppBackground").ignoresSafeArea())
        .navigationTitle("Help & Info")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Sections

    private var aboutSection: some View {
        Section("About") {
            Text("Drinky Poo helps you track your alcohol-free days, build streaks, and stay accountable to your personal goals — without judgment.")
                .foregroundStyle(Color("PrimaryText"))
                .padding(.vertical, 4)
        }
    }

    private var howToUseSection: some View {
        Section("How to Use") {
            infoRow(icon: "sun.max.fill", color: Color("DryDayColor"),
                    title: "Log a dry day",
                    detail: "Tap Dry Day on the Home tab. You can log any day from the Calendar tab too.")
            infoRow(icon: "drop.fill", color: Color("DrinkingDayColor"),
                    title: "Log a drinking day",
                    detail: "Tap Drinking on the Home tab. Honest tracking gives you the most useful stats.")
            infoRow(icon: "calendar", color: Color("AccentBlue"),
                    title: "Edit past days",
                    detail: "Tap any day on the Calendar tab to log, change, or remove it.")
            infoRow(icon: "arrow.uturn.left.circle.fill", color: Color("SecondaryText"),
                    title: "Change today's log",
                    detail: "Tap the logged day button on Home — it opens a sheet to flip or remove the entry.")
        }
    }

    private var statsSection: some View {
        Section("What the Stats Mean") {
            infoRow(icon: "flame.fill", color: Color("DryDayColor"),
                    title: "Dry Streak",
                    detail: "Consecutive dry days ending today. If today is unlogged, counts from yesterday.")
            infoRow(icon: "drop.fill", color: Color("DrinkingDayColor"),
                    title: "Drink Streak",
                    detail: "Consecutive drinking days ending today (or yesterday if today is unlogged).")
            infoRow(icon: "chart.pie.fill", color: Color("AccentBlue"),
                    title: "YTD Dry %",
                    detail: "Dry days ÷ total logged days this calendar year. Unlogged days are not counted.")
            infoRow(icon: "trophy.fill", color: .yellow,
                    title: "Best Streak",
                    detail: "Your all-time longest dry streak across every day you've ever logged.")
            infoRow(icon: "chart.bar.fill", color: Color("AccentBlue"),
                    title: "Goal Progress Bar",
                    detail: "The filled bar shows your actual YTD dry rate. The vertical line marks your goal. Green means you're at or above goal.")
        }
    }

    private var milestonesSection: some View {
        Section {
            Text("Hit one of these dry streaks and you'll get a confetti celebration:")
                .font(.subheadline)
                .foregroundStyle(Color("SecondaryText"))
                .padding(.vertical, 2)
            let milestones = [7, 14, 30, 60, 90, 120, 150, 180, 365]
            FlowLayout(spacing: 8) {
                ForEach(milestones, id: \.self) { days in
                    Text("\(days) days")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color("DryDayColor").opacity(0.15))
                        .foregroundStyle(Color("DryDayColor"))
                        .clipShape(Capsule())
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("Milestones")
        } footer: {
            Text("Each milestone is celebrated once. Keep going for the next one!")
        }
    }

    private var privacySection: some View {
        Section("Privacy") {
            infoRow(icon: "icloud.fill", color: Color("AccentBlue"),
                    title: "iCloud Sync",
                    detail: "Your data syncs privately across your devices via iCloud. Apple cannot read it.")
            infoRow(icon: "lock.fill", color: Color("DryDayColor"),
                    title: "No tracking",
                    detail: "No analytics, no ads, no third-party SDKs. Your data stays yours.")
        }
    }

    private var versionSection: some View {
        Section {
            HStack {
                Text("Version")
                    .foregroundStyle(Color("PrimaryText"))
                Spacer()
                Text(appVersion)
                    .foregroundStyle(Color("SecondaryText"))
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Helpers

    private func infoRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 24)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color("PrimaryText"))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(Color("SecondaryText"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Simple flow layout for milestone chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                y += rowH + spacing
                x = 0
                rowH = 0
            }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                y += rowH + spacing
                x = bounds.minX
                rowH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: .unspecified)
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}

#Preview {
    NavigationStack { InfoView() }
        .modelContainer(for: DayEntry.self, inMemory: true)
}
