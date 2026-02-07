import SwiftUI

struct RippleEffect: ViewModifier {
    let isActive: Bool
    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.accentColor.opacity(0),
                                    Color.accentColor.opacity(Theme.Opacity.rippleAccent),
                                    Color.accentColor.opacity(0)
                                ],
                                startPoint: UnitPoint(x: progress - 0.3, y: 0.5),
                                endPoint: UnitPoint(x: progress + 0.3, y: 0.5)
                            )
                        )
                        .opacity(isActive ? 1 : 0)
                }
            }
            .onChange(of: isActive) { _, active in
                if active {
                    progress = -0.3
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        progress = 1.3
                    }
                }
            }
    }
}

extension View {
    func rippleEffect(isActive: Bool) -> some View {
        modifier(RippleEffect(isActive: isActive))
    }
}
