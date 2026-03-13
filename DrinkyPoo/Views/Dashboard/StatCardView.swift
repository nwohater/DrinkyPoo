import SwiftUI

struct StatCardView: View {
    let title: String
    let value: String
    let icon: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(Color("DryDayColor"))

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(Color("PrimaryText"))
                .minimumScaleFactor(0.6)
                .lineLimit(1)

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(Color("SecondaryText"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
                .shadow(
                    color: colorScheme == .dark ? .clear : .black.opacity(0.07),
                    radius: 6, x: 0, y: 2
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(
                            colorScheme == .dark ? Color.white.opacity(0.1) : .clear,
                            lineWidth: 1
                        )
                )
        )
    }
}

#Preview {
    HStack(spacing: 12) {
        StatCardView(title: "Dry Streak", value: "14", icon: "flame.fill")
        StatCardView(title: "Drink Streak", value: "0", icon: "drop.fill")
        StatCardView(title: "YTD Dry", value: "58%", icon: "chart.pie.fill")
    }
    .padding()
    .background(Color("AppBackground"))
}
