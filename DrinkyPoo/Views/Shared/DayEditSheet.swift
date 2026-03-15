import SwiftUI

/// Bottom sheet for logging or changing a single day's state.
/// Used by both CalendarView (any past day) and DashboardView (today).
struct DayEditSheet: View {
    let date: Date
    let currentState: DayState?
    let onLog: (DayState) -> Void
    let onRemove: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.secondary.opacity(0.4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)

            Text(date, format: .dateTime.weekday(.wide).month(.wide).day().year())
                .font(.headline)
                .foregroundStyle(Color("PrimaryText"))

            HStack(spacing: 16) {
                logButton(label: "Dry Day", icon: "sun.max.fill",
                          color: Color("DryDayColor"), state: .dry)
                logButton(label: "Drinking", icon: "drop.fill",
                          color: Color("DrinkingDayColor"), state: .drinking)
            }
            .padding(.horizontal)

            if currentState != nil {
                Button(role: .destructive) {
                    onRemove()
                    dismiss()
                } label: {
                    Text("Remove Log")
                        .font(.subheadline)
                        .foregroundStyle(Color("SecondaryText"))
                }
            }

            Spacer()
        }
        .background(Color("AppBackground").ignoresSafeArea())
    }

    private func logButton(label: String, icon: String, color: Color, state: DayState) -> some View {
        let isCurrent = currentState == state
        return Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            onLog(state)
            dismiss()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title)
                    .symbolRenderingMode(.hierarchical)
                Text(label)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isCurrent ? color : color.opacity(0.15))
            )
            .foregroundStyle(isCurrent ? .white : color)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isCurrent ? .clear : color.opacity(0.4), lineWidth: 1.5)
            )
        }
        .disabled(isCurrent)
    }
}

#Preview {
    DayEditSheet(date: Date(), currentState: .dry, onLog: { _ in }, onRemove: {})
        .presentationDetents([.height(300)])
}
