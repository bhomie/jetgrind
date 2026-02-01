import SwiftUI

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var color: Color
    var scale: CGFloat
    var rotation: Double
    var rotationSpeed: Double
}

struct ConfettiView: View {
    let isActive: Bool
    let bounds: CGRect
    
    @State private var particles: [Particle] = []
    @State private var animationProgress: CGFloat = 0
    
    private let colors: [Color] = [
        .yellow, .orange, .pink, .purple, .blue, .green, .mint
    ]
    
    var body: some View {
        Canvas { context, size in
            let elapsed = animationProgress
            
            for particle in particles {
                let gravity: CGFloat = 400
                let x = particle.x + particle.vx * elapsed
                let y = particle.y + particle.vy * elapsed + 0.5 * gravity * elapsed * elapsed
                let rotation = Angle(degrees: particle.rotation + particle.rotationSpeed * Double(elapsed))
                let opacity = max(0, 1 - elapsed * 1.5)
                let scale = particle.scale * (1 - elapsed * 0.3)
                
                guard y < size.height + 20, opacity > 0 else { continue }
                
                context.opacity = opacity
                context.translateBy(x: x, y: y)
                context.rotate(by: rotation)
                context.scaleBy(x: scale, y: scale)
                
                let rect = CGRect(x: -3, y: -3, width: 6, height: 6)
                context.fill(
                    RoundedRectangle(cornerRadius: 1).path(in: rect),
                    with: .color(particle.color)
                )
                
                context.scaleBy(x: 1/scale, y: 1/scale)
                context.rotate(by: -rotation)
                context.translateBy(x: -x, y: -y)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active {
                spawnParticles()
                animateParticles()
            }
        }
    }
    
    private func spawnParticles() {
        particles = (0..<20).map { _ in
            let centerX = bounds.midX
            let centerY = bounds.midY
            let angle = Double.random(in: -Double.pi * 0.8 ..< -Double.pi * 0.2)
            let speed = CGFloat.random(in: 150...300)
            
            return Particle(
                x: centerX + CGFloat.random(in: -20...20),
                y: centerY,
                vx: cos(angle) * speed,
                vy: sin(angle) * speed,
                color: colors.randomElement() ?? .yellow,
                scale: CGFloat.random(in: 0.8...1.2),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: -720...720)
            )
        }
        animationProgress = 0
    }
    
    private func animateParticles() {
        withAnimation(.linear(duration: 0.8)) {
            animationProgress = 0.8
        }
    }
}

struct ConfettiOverlay: ViewModifier {
    let isActive: Bool
    
    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    ConfettiView(isActive: isActive, bounds: geometry.frame(in: .local))
                }
            }
    }
}

extension View {
    func confettiOverlay(isActive: Bool) -> some View {
        modifier(ConfettiOverlay(isActive: isActive))
    }
}
