import SwiftUI

struct CompletedPillAnchorKey: PreferenceKey {
    nonisolated(unsafe) static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension View {
    func completedPillAnchor() -> some View {
        background(GeometryReader { geometry in
            Color.clear.preference(
                key: CompletedPillAnchorKey.self,
                value: geometry.frame(in: .global)
            )
        })
    }
}
