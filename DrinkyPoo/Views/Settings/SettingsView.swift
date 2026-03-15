import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("goalPercent")    private var goalPercent: Double = 50.0
    @AppStorage("reminderEnabled") private var reminderEnabled: Bool = false
    @AppStorage("reminderHour")   private var reminderHour: Int = 21
    @AppStorage("reminderMinute") private var reminderMinute: Int = 0
    @AppStorage("appearanceMode") private var appearanceMode: String = "system"

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DayEntry.date) private var entries: [DayEntry]

    @State private var reminderTime: Date = Date()
    @State private var showClearConfirm = false
    @State private var selectedShareYear: Int = Calendar.current.component(.year, from: Date())
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    private var availableYears: [Int] {
        let cal = Calendar.current
        let years = Set(entries.map { cal.component(.year, from: $0.date) })
        return years.sorted().reversed()
    }

    var body: some View {
        Form {
            goalSection
            reminderSection
            appearanceSection
            shareSection
            dataSection
        }
        .scrollContentBackground(.hidden)
        .background(Color("AppBackground").ignoresSafeArea())
        .navigationTitle("Settings")
        .onAppear {
            syncReminderTime()
            if let first = availableYears.first { selectedShareYear = first }
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ActivityView(activityItems: [image])
            }
        }
        .confirmationDialog(
            "Clear All Data?",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete All Entries", role: .destructive) { clearAll() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently removes all logged days and cannot be undone.")
        }
    }

    // MARK: - Goal

    private var goalSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Dry Day Goal")
                    Spacer()
                    Text("\(Int(goalPercent))%")
                        .foregroundStyle(Color("SecondaryText"))
                        .monospacedDigit()
                }
                Slider(value: $goalPercent, in: 0...100, step: 1)
                    .tint(Color("DryDayColor"))
            }
            .padding(.vertical, 4)
        } header: {
            Text("Goal")
        } footer: {
            Text("Target percentage of dry days per month shown on the dashboard.")
        }
    }

    // MARK: - Reminders

    private var reminderSection: some View {
        Section {
            Toggle("Daily Reminder", isOn: $reminderEnabled)
                .tint(Color("AccentBlue"))
                .onChange(of: reminderEnabled) { _, enabled in
                    Task { await toggleReminder(enabled) }
                }
            if reminderEnabled {
                DatePicker(
                    "Reminder Time",
                    selection: $reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: reminderTime) { _, newTime in
                    let cal = Calendar.current
                    reminderHour   = cal.component(.hour,   from: newTime)
                    reminderMinute = cal.component(.minute, from: newTime)
                    scheduleReminder()
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Reminds you to log each day if you haven't already.")
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $appearanceMode) {
                Text("System").tag("system")
                Text("Light").tag("light")
                Text("Dark").tag("dark")
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Share

    private var shareSection: some View {
        Section {
            if availableYears.count > 1 {
                Picker("Year", selection: $selectedShareYear) {
                    ForEach(availableYears, id: \.self) { year in
                        Text(String(year)).tag(year)
                    }
                }
            }
            Button {
                if let image = renderYearSummary(year: selectedShareYear, entries: Array(entries)) {
                    shareImage = image
                    showShareSheet = true
                }
            } label: {
                Label("Share Year Summary", systemImage: "square.and.arrow.up")
            }
            .disabled(entries.isEmpty)
        } header: {
            Text("Summary")
        } footer: {
            Text("Share a visual summary of your year — great for tracking progress with a doctor or support group.")
        }
    }

    // MARK: - Data

    private var dataSection: some View {
        Section("Data") {
            ShareLink(
                item: csvString(),
                preview: SharePreview(
                    "DrinkyPoo_Export.csv",
                    image: Image(systemName: "doc.text")
                )
            ) {
                Label("Export CSV", systemImage: "square.and.arrow.up")
            }
            .disabled(entries.isEmpty)

            Button(role: .destructive) {
                showClearConfirm = true
            } label: {
                Label("Clear All Data", systemImage: "trash")
            }
            .disabled(entries.isEmpty)
        }
    }

    // MARK: - Helpers

    private func syncReminderTime() {
        var comps = DateComponents()
        comps.hour   = reminderHour
        comps.minute = reminderMinute
        reminderTime = Calendar.current.date(from: comps) ?? Date()
    }

    private func toggleReminder(_ enabled: Bool) async {
        if enabled {
            let granted = await NotificationManager.shared.requestPermission()
            if granted {
                scheduleReminder()
            } else {
                reminderEnabled = false
            }
        } else {
            NotificationManager.shared.cancelDailyReminder()
        }
    }

    private func scheduleReminder() {
        var comps = DateComponents()
        comps.hour   = reminderHour
        comps.minute = reminderMinute
        NotificationManager.shared.scheduleDailyReminder(at: comps)
    }

    private func clearAll() {
        for entry in entries { modelContext.delete(entry) }
    }

    private func csvString() -> String {
        let fmt = ISO8601DateFormatter()
        var lines = ["date,state,createdAt,updatedAt"]
        for entry in entries.sorted(by: { $0.date < $1.date }) {
            lines.append([
                fmt.string(from: entry.date),
                entry.stateRaw,
                fmt.string(from: entry.createdAt),
                fmt.string(from: entry.updatedAt)
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n")
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: DayEntry.self, inMemory: true)
}
