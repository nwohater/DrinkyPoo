import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \DayEntry.date) private var entries: [DayEntry]

    @AppStorage("goalPercent") private var goalPercent: Double = 50.0

    @State private var viewModel = AppViewModel()
    @State private var showFlipSheet = false
    @State private var showConfetti = false

    @AppStorage("celebratedMilestones") private var celebratedMilestonesRaw: String = ""

    private var celebratedMilestones: Set<Int> {
        Set(celebratedMilestonesRaw.split(separator: ",").compactMap { Int($0) })
    }

    private func markCelebrated(_ milestone: Int) {
        var set = celebratedMilestones
        set.insert(milestone)
        celebratedMilestonesRaw = set.map(String.init).joined(separator: ",")
    }

    private var todayEntry: DayEntry? { viewModel.entry(for: Date()) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // MARK: Header
                VStack(spacing: 8) {
                    Text("Drinky Poo")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color("DryDayColor"),
                                    Color("DrinkingDayColor")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .shadow(color: Color("DryDayColor").opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // MARK: Stat cards
                HStack(spacing: 12) {
                    StatCardView(
                        title: "Dry Streak",
                        value: "\(viewModel.currentDryStreak)",
                        icon: "flame.fill"
                    )
                    StatCardView(
                        title: "Drink Streak",
                        value: "\(viewModel.currentDrinkingStreak)",
                        icon: "drop.fill"
                    )
                    StatCardView(
                        title: "YTD Dry",
                        value: String(format: "%.0f%%", viewModel.ytdDryPercent),
                        icon: "chart.pie.fill"
                    )
                }
                .padding(.horizontal)

                // MARK: Goal progress
                GoalProgressView(
                    ytdDryPercent: viewModel.ytdDryPercent,
                    goalPercent: goalPercent,
                    dryCount: viewModel.ytdDryCount,
                    daysElapsed: viewModel.daysElapsedInYear
                )
                .padding(.horizontal)

                // MARK: Last 7 days
                last7DaysCard
                    .padding(.horizontal)

                // MARK: This month
                thisMonthCard
                    .padding(.horizontal)

                // MARK: Log button
                logButton
                    .padding(.horizontal)
                    .padding(.bottom, 16)
            }
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .confetti(isActive: $showConfetti)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    let year = Calendar.current.component(.year, from: Date())
                    shareYearSummary(year: year, entries: Array(entries))
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
        .onChange(of: entries) { _, newEntries in
            viewModel.update(entries: newEntries)
            viewModel.goalPercent = goalPercent
            checkMilestone()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                viewModel.update(entries: entries)
                viewModel.goalPercent = goalPercent
            }
        }
        .onAppear {
            viewModel.update(entries: entries)
            viewModel.goalPercent = goalPercent
        }
        .sheet(isPresented: $showFlipSheet) {
            DayEditSheet(
                date: Date(),
                currentState: todayEntry?.state,
                onLog: { newState in
                    viewModel.upsertDay(state: newState, context: modelContext)
                },
                onRemove: {
                    viewModel.removeEntry(for: Date(), context: modelContext)
                }
            )
            .presentationDetents([.height(300)])
            .presentationCornerRadius(20)
        }
    }

    // MARK: - Last 7 days card

    private var last7DaysCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            HStack(spacing: 0) {
                ForEach(viewModel.last7Days, id: \.date) { day in
                    VStack(spacing: 6) {
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2)
                            .foregroundStyle(Color("SecondaryText"))
                        Circle()
                            .fill(dotColor(for: day.state))
                            .frame(width: 28, height: 28)
                            .overlay {
                                if Calendar.current.isDateInToday(day.date) {
                                    Circle().stroke(Color("PrimaryText"), lineWidth: 2)
                                }
                            }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func dotColor(for state: DayState?) -> Color {
        switch state {
        case .dry:      return Color("DryDayColor")
        case .drinking: return Color("DrinkingDayColor")
        case .none:     return Color.secondary.opacity(0.2)
        }
    }

    // MARK: - This month card

    private var thisMonthCard: some View {
        let stats   = viewModel.currentMonthStats
        let total   = stats.dry + stats.drinking
        let pct     = total > 0 ? Int(Double(stats.dry) / Double(total) * 100) : 0
        let needed  = viewModel.dryDaysNeededForGoal(goalPercent: goalPercent)
        let remaining = viewModel.daysRemainingInMonth

        return VStack(alignment: .leading, spacing: 12) {
            Text(Date().formatted(.dateTime.month(.wide)))
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stats.dry)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(Color("DryDayColor"))
                    Text("dry")
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(stats.drinking)")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(Color("DrinkingDayColor"))
                    Text("drinking")
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(pct)%")
                        .font(.title2.bold().monospacedDigit())
                        .foregroundStyle(Color("PrimaryText"))
                    Text("dry rate")
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }
            }

            if total > 0 {
                if needed == 0 {
                    Label("On track for goal this month", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color("DryDayColor"))
                } else if remaining == 0 {
                    Label("Goal not reached this month", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color("DrinkingDayColor"))
                } else if needed > remaining {
                    Label("Goal out of reach — \(needed) needed, \(remaining) days left", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color("DrinkingDayColor"))
                } else {
                    Text("Need \(needed) more dry \(needed == 1 ? "day" : "days") in \(remaining) remaining to hit goal")
                        .font(.caption)
                        .foregroundStyle(Color("SecondaryText"))
                }
            }
        }
        .padding(16)
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Log button

    @ViewBuilder
    private var logButton: some View {
        if let entry = todayEntry {
            // Already logged — show state + tap to flip
            Button {
                showFlipSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: entry.state == .dry ? "checkmark.circle.fill" : "circle.fill")
                        .symbolRenderingMode(.hierarchical)
                    Text(entry.state == .dry ? "Today: Dry Day ✓" : "Today: Drinking Day")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(entry.state == .dry ? Color("DryDayColor") : Color("DrinkingDayColor"))
                )
                .foregroundStyle(.white)
                .font(.title3)
            }
        } else {
            // Unlogged — primary call to action
            HStack(spacing: 16) {
                logActionButton(label: "Dry Day", state: .dry, icon: "sun.max.fill")
                logActionButton(label: "Drinking", state: .drinking, icon: "drop.fill")
            }
        }
    }

    private func checkMilestone() {
        let streak = viewModel.currentDryStreak
        guard let milestone = dryStreakMilestones.first(where: { $0 == streak }),
              !celebratedMilestones.contains(milestone) else { return }
        markCelebrated(milestone)
        showConfetti = true
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            showConfetti = false
        }
    }

    private func logActionButton(label: String, state: DayState, icon: String) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.upsertDay(state: state, context: modelContext)
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolRenderingMode(.hierarchical)
                Text(label)
                    .fontWeight(.semibold)
                    .font(.callout)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(state == .dry ? Color("DryDayColor") : Color("DrinkingDayColor"))
            )
            .foregroundStyle(.white)
        }
    }
}


#Preview {
    DashboardView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
