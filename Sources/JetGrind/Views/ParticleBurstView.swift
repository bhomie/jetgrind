import SwiftUI

struct ParticleBurstView: View {
    let color: Color
    private let particleCount = 10

    @State private var particles: [Particle] = []
    @State private var animate = false

    struct Particle: Identifiable {
        let id = UUID()
        let angle: Double
        let distance: CGFloat
        let hueShift: Double
    }

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let progress = animate ? 1.0 : 0.0

            for particle in particles {
                let dx = cos(particle.angle) * particle.distance * progress
                let dy = sin(particle.angle) * particle.distance * progress
                let point = CGPoint(x: center.x + dx, y: center.y + dy)
                let opacity = max(0, 1.0 - progress)
                let radius: CGFloat = 2.5 * (1.0 - progress * 0.5)

                context.opacity = opacity
                let rect = CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2)
                context.fill(Circle().path(in: rect), with: .color(color.opacity(0.8)))
            }
        }
        .onAppear {
            particles = (0..<particleCount).map { _ in
                Particle(
                    angle: Double.random(in: 0...(2 * .pi)),
                    distance: CGFloat.random(in: 12...22),
                    hueShift: Double.random(in: -0.1...0.1)
                )
            }
            withAnimation(.easeOut(duration: 0.5)) {
                animate = true
            }
        }
        .allowsHitTesting(false)
    }
}
