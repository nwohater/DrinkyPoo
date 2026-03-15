import SwiftUI

struct GoalProgressView: View {
    let ytdDryPercent: Double
    let goalPercent: Double
    let dryCount: Int
    let loggedCount: Int

    private var progress: Double {
        min(ytdDryPercent / max(goalPercent, 1), 1.0)
    }

    private var barColor: Color {
        if ytdDryPercent >= goalPercent {
            return Color("DryDayColor")
        } else if ytdDryPercent >= goalPercent - 10 {
            return .orange
        } else {
            return Color("ProgressGoalLine")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.secondary.opacity(0.15))
                        .frame(height: 12)

                    // Fill
                    RoundedRectangle(cornerRadius: 6)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 12)
                        .animation(.easeOut(duration: 0.4), value: progress)

                    // Goal marker
                    let markerX = geo.size.width * min(goalPercent / 100, 1.0)
                    Rectangle()
                        .fill(Color("ProgressGoalLine"))
                        .frame(width: 2, height: 18)
                        .offset(x: markerX - 1, y: -3)
                }
            }
            .frame(height: 12)

            Text("\(dryCount) of \(loggedCount) logged days dry this year (\(Int(goalPercent))% goal)")
                .font(.caption)
                .foregroundStyle(Color("SecondaryText"))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color("CardBackground"))
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        GoalProgressView(ytdDryPercent: 62, goalPercent: 50, dryCount: 45, loggedCount: 72)
        GoalProgressView(ytdDryPercent: 43, goalPercent: 50, dryCount: 31, loggedCount: 72)
        GoalProgressView(ytdDryPercent: 30, goalPercent: 50, dryCount: 22, loggedCount: 72)
    }
    .padding()
    .background(Color("AppBackground"))
}
