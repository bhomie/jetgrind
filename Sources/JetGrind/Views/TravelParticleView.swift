import SwiftUI

struct TravelParticle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var color: Color
    var scale: CGFloat
    var opacity: CGFloat = 1.0
    var age: CGFloat = 0
}

struct TravelParticleView: View {
    let position: CGPoint
    let isActive: Bool
    
    @State private var particles: [TravelParticle] = []
    @State private var lastSpawnTime: Date = .now
    
    private let colors: [Color] = [
        .yellow, .orange, .pink, .purple, .blue, .green, .mint
    ]
    
    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                for particle in particles {
                    let elapsed = particle.age
                    let x = particle.x + particle.vx * elapsed
                    let y = particle.y + particle.vy * elapsed + 50 * elapsed * elapsed
                    let opacity = max(0, 1 - elapsed * 3)
                    let scale = particle.scale * (1 - elapsed * 0.5)
                    
                    guard opacity > 0 else { continue }
                    
                    context.opacity = opacity
                    
                    let rect = CGRect(
                        x: x - 2 * scale,
                        y: y - 2 * scale,
                        width: 4 * scale,
                        height: 4 * scale
                    )
                    context.fill(
                        Circle().path(in: rect),
                        with: .color(particle.color)
                    )
                }
            }
            .onChange(of: timeline.date) { _, newDate in
                updateParticles(currentTime: newDate)
                if isActive {
                    spawnParticleIfNeeded(currentTime: newDate)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .onChange(of: isActive) { wasActive, nowActive in
            if nowActive && !wasActive {
                lastSpawnTime = .now
                spawnParticle()
            }
        }
    }
    
    private func updateParticles(currentTime: Date) {
        particles = particles.compactMap { particle in
            var p = particle
            p.age += 0.016 // ~60fps
            return p.age < 0.4 ? p : nil
        }
    }
    
    private func spawnParticleIfNeeded(currentTime: Date) {
        let elapsed = currentTime.timeIntervalSince(lastSpawnTime)
        if elapsed > 0.03 { // Spawn every 30ms
            spawnParticle()
            lastSpawnTime = currentTime
        }
    }
    
    private func spawnParticle() {
        let particle = TravelParticle(
            x: position.x + CGFloat.random(in: -8...8),
            y: position.y + CGFloat.random(in: -4...4),
            vx: CGFloat.random(in: -30...30),
            vy: CGFloat.random(in: -20...10),
            color: colors.randomElement() ?? .yellow,
            scale: CGFloat.random(in: 0.6...1.2)
        )
        particles.append(particle)
    }
}
