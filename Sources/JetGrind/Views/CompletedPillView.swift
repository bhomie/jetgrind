import SwiftUI

struct CompletedPillView: View {
    let count: Int
    var focus: FocusState<TodoFocus?>.Binding
    let lastIncompleteTaskId: UUID?
    let onOpen: () -> Void
    var taskAbsorbed: UUID?

    @State private var bounceScale: CGFloat = 1.0
    @State private var countScale: CGFloat = 1.0

    private var isFocused: Bool {
        focus.wrappedValue == .completedPill
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
            Text("\(count) done")
                .contentTransition(.numericText())
                .scaleEffect(countScale)
        }
        .font(.system(size: 10, weight: .medium))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.accentColor, lineWidth: isFocused ? 2 : 0)
                )
        )
        .scaleEffect(bounceScale)
        .completedPillAnchor()
        .focusable()
        .focused(focus, equals: .completedPill)
        .focusEffectDisabled()
        .onTapGesture {
            onOpen()
        }
        .onKeyPress(.upArrow) {
            if let lastId = lastIncompleteTaskId {
                focus.wrappedValue = .task(lastId)
            } else {
                focus.wrappedValue = .input
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            onOpen()
            return .handled
        }
        .onKeyPress(.space) {
            onOpen()
            return .handled
        }
        .onKeyPress(.return) {
            onOpen()
            return .handled
        }
        .onChange(of: taskAbsorbed) { _, newValue in
            if newValue != nil {
                triggerBounce()
            }
        }
    }

    private func triggerBounce() {
        // Bounce the pill
        withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
            bounceScale = 1.15
        }
        
        // Return to normal
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bounceScale = 1.0
            }
        }
        
        // Scale pop on count
        withAnimation(.spring(response: 0.15, dampingFraction: 0.5)) {
            countScale = 1.15
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                countScale = 1.0
            }
        }
    }
}
