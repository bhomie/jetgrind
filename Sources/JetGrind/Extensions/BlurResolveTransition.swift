import SwiftUI

private struct BlurResolveModifier: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(active ? 0.85 : 1)
            .blur(radius: active ? 6 : 0)
            .opacity(active ? 0 : 1)
    }
}

extension AnyTransition {
    static var blurResolve: AnyTransition {
        .modifier(
            active: BlurResolveModifier(active: true),
            identity: BlurResolveModifier(active: false)
        )
    }
}
