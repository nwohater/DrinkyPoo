import SwiftUI
import UIKit

// MARK: - Milestone constants
let dryStreakMilestones = [7, 14, 30, 60, 90, 120, 150, 180, 365]

// MARK: - ConfettiView
struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> ConfettiUIView {
        ConfettiUIView()
    }

    func updateUIView(_ uiView: ConfettiUIView, context: Context) {}

    // MARK: - UIView subclass so layoutSubviews gives us real bounds
    final class ConfettiUIView: UIView {
        private let emitter = CAEmitterLayer()
        private var didStart = false

        override init(frame: CGRect) {
            super.init(frame: frame)
            isUserInteractionEnabled = false
            backgroundColor = .clear
            layer.addSublayer(emitter)
        }
        required init?(coder: NSCoder) { fatalError() }

        override func layoutSubviews() {
            super.layoutSubviews()
            emitter.frame = bounds
            let w = bounds.width > 0 ? bounds.width : UIScreen.main.bounds.width
            emitter.emitterPosition = CGPoint(x: w / 2, y: -10)
            emitter.emitterSize = CGSize(width: w, height: 1)
            guard !didStart else { return }
            didStart = true
            startEmitting()
        }

        private func startEmitting() {
            let colors: [UIColor] = [
                UIColor(named: "DryDayColor") ?? .systemGreen,
                UIColor(named: "DrinkingDayColor") ?? .systemRed,
                UIColor(named: "AccentBlue") ?? .systemBlue,
                .systemYellow, .systemPurple, .systemOrange, .white
            ]
            emitter.emitterShape = .line
            emitter.beginTime = CACurrentMediaTime()
            emitter.birthRate = 1
            emitter.emitterCells = colors.flatMap { color in
                [makeCell(color: color, shape: .circle),
                 makeCell(color: color, shape: .rect)]
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.emitter.birthRate = 0
            }
        }

        private enum ParticleShape { case circle, rect }

        private func makeCell(color: UIColor, shape: ParticleShape) -> CAEmitterCell {
            let cell = CAEmitterCell()
            cell.contents = particleImage(color: color, shape: shape)?.cgImage
            cell.birthRate = 12
            cell.lifetime = 4.5
            cell.velocity = CGFloat.random(in: 200...400)
            cell.velocityRange = 80
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 5
            cell.spin = CGFloat.random(in: 1...4)
            cell.spinRange = 3
            cell.scale = CGFloat.random(in: 0.06...0.14)
            cell.scaleRange = 0.04
            cell.alphaSpeed = -0.25
            cell.yAcceleration = 120
            cell.xAcceleration = CGFloat.random(in: -40...40)
            return cell
        }

        private func particleImage(color: UIColor, shape: ParticleShape) -> UIImage? {
            let size = CGSize(width: 12, height: 12)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { ctx in
                ctx.cgContext.setFillColor(color.cgColor)
                switch shape {
                case .circle:
                    ctx.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
                case .rect:
                    ctx.cgContext.fill(CGRect(x: 1, y: 3, width: 10, height: 6))
                }
            }
        }
    }
}

// MARK: - Milestone check (call after any day is logged)
@MainActor
func checkDryMilestone(entries: [DayEntry]) {
    // Compute current dry streak from the provided entries
    let cal = Calendar.current
    var date = cal.startOfDay(for: Date())
    let lookup = Dictionary(uniqueKeysWithValues: entries.map { (cal.startOfDay(for: $0.date), $0.state) })

    if lookup[date] == nil {
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: date) else { return }
        date = yesterday
    }

    var streak = 0
    var cursor = date
    while let state = lookup[cursor], state == .dry {
        streak += 1
        guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
        cursor = prev
    }

    print("🎉 checkDryMilestone: streak=\(streak), milestones=\(dryStreakMilestones)")

    guard let milestone = dryStreakMilestones.first(where: { $0 == streak }) else {
        print("🎉 No milestone match for streak \(streak)")
        return
    }

    let key = "celebratedDryMilestones"
    let raw = UserDefaults.standard.string(forKey: key) ?? ""
    let celebrated = Set(raw.split(separator: ",").compactMap { Int($0) })
    print("🎉 Milestone \(milestone) hit! Already celebrated: \(celebrated)")
    guard !celebrated.contains(milestone) else {
        print("🎉 Already celebrated \(milestone), skipping")
        return
    }

    var updated = celebrated
    updated.insert(milestone)
    UserDefaults.standard.set(updated.map(String.init).joined(separator: ","), forKey: key)

    NotificationCenter.default.post(name: .dryMilestoneReached, object: nil)
    UINotificationFeedbackGenerator().notificationOccurred(.success)
}
