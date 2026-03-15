import SwiftUI
import UIKit

// MARK: - Milestone constants
let dryStreakMilestones = [7, 14, 30, 60, 90, 120, 150, 180, 365]

// MARK: - ConfettiView
struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        view.backgroundColor = .clear

        let emitter = CAEmitterLayer()
        emitter.emitterShape = .line
        emitter.beginTime = CACurrentMediaTime()
        emitter.birthRate = 1

        let colors: [UIColor] = [
            UIColor(named: "DryDayColor") ?? .systemGreen,
            UIColor(named: "DrinkingDayColor") ?? .systemRed,
            UIColor(named: "AccentBlue") ?? .systemBlue,
            .systemYellow,
            .systemPurple,
            .systemOrange,
            .white
        ]

        emitter.emitterCells = colors.flatMap { color in
            [makeCell(color: color, shape: .circle),
             makeCell(color: color, shape: .rect)]
        }

        view.layer.addSublayer(emitter)

        // Layout after a brief delay so bounds are set
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            emitter.emitterPosition = CGPoint(x: view.bounds.midX, y: -10)
            emitter.emitterSize = CGSize(width: view.bounds.width, height: 1)
        }

        // Stop emitting after 1.5s so particles just fall and fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            emitter.birthRate = 0
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let emitter = uiView.layer.sublayers?.first as? CAEmitterLayer else { return }
        emitter.emitterPosition = CGPoint(x: uiView.bounds.midX, y: -10)
        emitter.emitterSize = CGSize(width: uiView.bounds.width, height: 1)
    }

    private enum ParticleShape { case circle, rect }

    private func makeCell(color: UIColor, shape: ParticleShape) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.contents = particleImage(color: color, shape: shape)?.cgImage
        cell.birthRate = 12
        cell.lifetime = 4.5
        cell.velocity = CGFloat.random(in: 200...400)
        cell.velocityRange = 80
        cell.emissionLongitude = .pi            // downward
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

// MARK: - Overlay modifier
struct ConfettiModifier: ViewModifier {
    @Binding var isActive: Bool

    func body(content: Content) -> some View {
        content.overlay {
            if isActive {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}

extension View {
    func confetti(isActive: Binding<Bool>) -> some View {
        modifier(ConfettiModifier(isActive: isActive))
    }
}
