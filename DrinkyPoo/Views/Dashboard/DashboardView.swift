import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayEntry.date) private var entries: [DayEntry]

    @AppStorage("goalPercent") private var goalPercent: Double = 50.0

    @State private var viewModel = AppViewModel()
    @State private var showFlipSheet = false

    private var todayEntry: DayEntry? { viewModel.entry(for: Date()) }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // MARK: Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Drinky Poo")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color("PrimaryText"))
                        Text(Date(), format: .dateTime.weekday(.wide).month(.wide).day())
                            .font(.subheadline)
                            .foregroundStyle(Color("SecondaryText"))
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)

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

                Spacer(minLength: 40)

                // MARK: Log button
                logButton
                    .padding(.horizontal)
                    .padding(.bottom, 24)
            }
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .onChange(of: entries) { _, newEntries in
            viewModel.update(entries: newEntries)
            viewModel.goalPercent = goalPercent
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

    private func logActionButton(label: String, state: DayState, icon: String) -> some View {
        Button {
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
